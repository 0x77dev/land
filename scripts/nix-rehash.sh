#!/usr/bin/env bash
# Refresh the per-platform SRI digests of a Nix package after a version bump.
#
# Renovate's custom regex manager bumps the comment-annotated `version = "...";`
# but cannot recompute Nix hashes itself. This script reads the package's
# `passthru.sources` (which already reflect the new version), re-prefetches every
# artifact, and rewrites the stale digests in place. Wired into Renovate via
# `postUpgradeTasks`, it lets multi-platform binary packages land fully updated.
#
# Usage: scripts/nix-rehash.sh <package-file> <flake-attr>
set -euo pipefail

file="${1:?usage: nix-rehash.sh <package-file> <flake-attr>}"
attr="${2:?usage: nix-rehash.sh <package-file> <flake-attr>}"

system="$(nix eval --raw --impure --expr 'builtins.currentSystem')"
sources="$(nix eval --json ".#packages.${system}.${attr}.sources")"

# `passthru.sources` is platform-agnostic data, so a single eval yields every
# artifact's url + currently-pinned hash regardless of the runner architecture.
jq -r 'to_entries[] | "\(.key)\t\(.value.url)\t\(.value.hash)"' <<<"$sources" |
  while IFS=$'\t' read -r name url oldhash; do
    newhash="$(nix store prefetch-file --json "$url" | jq -r '.hash')"
    if [ "$newhash" != "$oldhash" ]; then
      echo "nix-rehash: ${attr} (${name}): ${oldhash} -> ${newhash}"
      # base64 SRI hashes never contain '|', so it is a safe sed delimiter.
      tmp="$(mktemp)"
      sed "s|${oldhash}|${newhash}|g" "$file" >"$tmp"
      mv "$tmp" "$file"
    fi
  done
