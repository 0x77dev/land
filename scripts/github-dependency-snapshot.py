#!/usr/bin/env python3
"""Emit a GitHub dependency-submission snapshot for Nix flake inputs.

GitHub's dependency graph does not parse Nix flakes natively.  This bridge keeps
`flake.lock` visible to Dependabot/dependency-graph consumers without committing
any generated data: CI posts the JSON this script prints to the dependency
submission API.
"""

from __future__ import annotations

import datetime as dt
import json
import os
import re
import subprocess
import sys
import urllib.parse
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
LOCKFILE = ROOT / "flake.lock"


def _git(args: list[str], fallback: str) -> str:
    try:
        return subprocess.check_output(
            ["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return fallback


def _node_ref(value: Any) -> str | None:
    if isinstance(value, str):
        return value
    if isinstance(value, list) and value and isinstance(value[-1], str):
        return value[-1]
    return None


def _safe_qualifier(value: str) -> str:
    return urllib.parse.quote(value, safe="")


def _github_purl(owner: str, repo: str, rev: str) -> str:
    return f"pkg:github/{owner}/{repo}@{rev}"


def _generic_purl(
    name: str, version: str, qualifiers: dict[str, str] | None = None
) -> str:
    purl = f"pkg:generic/{urllib.parse.quote(name, safe='._+-')}@{_safe_qualifier(version)}"
    if qualifiers:
        query = urllib.parse.urlencode(sorted(qualifiers.items()))
        purl = f"{purl}?{query}"
    return purl


def _purl_for_locked(node_name: str, locked: dict[str, Any]) -> str | None:
    typ = locked.get("type")
    rev = locked.get("rev") or locked.get("narHash") or locked.get("lastModified")
    if typ == "github" and locked.get("owner") and locked.get("repo") and rev:
        return _github_purl(locked["owner"], locked["repo"], str(rev))

    if typ == "gitlab" and locked.get("owner") and locked.get("repo") and rev:
        name = f"gitlab/{locked['owner']}/{locked['repo']}"
        return _generic_purl(name, str(rev), {"type": "gitlab"})

    if typ in {"git", "mercurial"} and locked.get("url") and rev:
        parsed = urllib.parse.urlparse(locked["url"])
        path = parsed.path.rstrip("/").removesuffix(".git").lstrip("/")
        if parsed.netloc == "github.com" and path.count("/") >= 1:
            owner, repo, *_ = path.split("/")
            return _github_purl(owner, repo, str(rev))
        name = re.sub(r"[^A-Za-z0-9._+-]+", "-", f"{parsed.netloc}/{path}".strip("/"))
        return _generic_purl(name or node_name, str(rev), {"type": typ})

    if typ in {"tarball", "file"} and locked.get("url") and rev:
        parsed = urllib.parse.urlparse(locked["url"])
        name = re.sub(
            r"[^A-Za-z0-9._+-]+", "-", f"{parsed.netloc}{parsed.path}".strip("/")
        )
        return _generic_purl(name or node_name, str(rev), {"type": typ})

    # Local/path inputs are part of this repository, not external dependencies.
    return None


def main() -> int:
    lock = json.loads(LOCKFILE.read_text())
    nodes: dict[str, dict[str, Any]] = lock["nodes"]
    root = nodes[lock.get("root", "root")]
    direct_refs = {_node_ref(v) for v in root.get("inputs", {}).values()}
    direct_refs.discard(None)

    node_to_purl: dict[str, str] = {}
    for name, node in nodes.items():
        if name == lock.get("root", "root"):
            continue
        locked = node.get("locked")
        if not isinstance(locked, dict):
            continue
        purl = _purl_for_locked(name, locked)
        if purl:
            node_to_purl[name] = purl

    resolved: dict[str, dict[str, Any]] = {}
    for name, node in nodes.items():
        purl = node_to_purl.get(name)
        if not purl:
            continue
        input_deps = []
        for value in node.get("inputs", {}).values():
            dep = _node_ref(value)
            if dep and dep in node_to_purl:
                input_deps.append(node_to_purl[dep])
        locked = node.get("locked", {})
        resolved[purl] = {
            "package_url": purl,
            "relationship": "direct" if name in direct_refs else "indirect",
            "scope": "runtime",
            "dependencies": sorted(set(input_deps)),
            "metadata": {
                "nix_node": name,
                "locked_type": str(locked.get("type", "")),
                "nar_hash": str(locked.get("narHash", "")),
            },
        }

    sha = os.environ.get("GITHUB_SHA") or _git(["rev-parse", "HEAD"], "unknown")
    ref = os.environ.get("GITHUB_REF") or _git(
        ["symbolic-ref", "HEAD"], "refs/heads/main"
    )
    repository = os.environ.get("GITHUB_REPOSITORY", "0x77dev/land")
    server_url = os.environ.get("GITHUB_SERVER_URL", "https://github.com")
    run_id = os.environ.get("GITHUB_RUN_ID", "local")
    run_attempt = os.environ.get("GITHUB_RUN_ATTEMPT", "1")
    workflow = os.environ.get("GITHUB_WORKFLOW", "dependency-graph")

    snapshot = {
        "version": 0,
        "sha": sha,
        "ref": ref,
        "job": {
            "correlator": f"{workflow}-{ref}",
            "id": f"{run_id}-{run_attempt}",
            "html_url": f"{server_url}/{repository}/actions/runs/{run_id}",
        },
        "detector": {
            "name": "land-nix-flake-lock",
            "version": "1.0.0",
            "url": f"{server_url}/{repository}",
        },
        "scanned": dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat(),
        "manifests": {
            "flake.lock": {
                "name": "flake.lock",
                "file": {"source_location": "flake.lock"},
                "resolved": resolved,
            }
        },
    }
    json.dump(snapshot, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
