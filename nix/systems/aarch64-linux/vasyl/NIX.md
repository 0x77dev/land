# Using Nix on this machine

This box is NixOS and Mykhailo lives in Nix. Use it the idiomatic, modern way.
Prefer Nix over ad-hoc installers; keep the system clean.

For what is actually installed and how this machine is wired, read the
auto-generated `ENVIRONMENT.md` first — it is rendered from the live config at
build time and never goes stale. It carries a serialized Nix snapshot of the
machine facts (host, kernel, resources, network edge, Nix features, registry
pins, store layout, users) plus a per-tool table with versions, licenses, and
descriptions read straight from each package's `meta`.

## Ephemeral tools — don't pollute the system

Reach for a tool you don't have? Run it from nixpkgs instead of installing it:

- One-off command: `nix run nixpkgs#<pkg> -- <args>`
- A shell with tools on PATH: `nix shell nixpkgs#<pkg> nixpkgs#<other>`
- Per-project environment: a `flake.nix` devShell entered with `nix develop`
  (or `direnv` + `nix-direnv`, already set up).

`nixpkgs#…` resolves to the exact revision pinned by this host's flake (the
registry and `NIX_PATH` are wired to it), so versions are reproducible. For a
newer build of something, the flake also pins an `unstable` input, so
`nix shell unstable#<pkg>` gives you the bleeding-edge package without touching
the system. Only add a package to the system config when it must be present
persistently for the agent.

Avoid imperative installs: no `nix-env -i`, no `nix profile install` for
throwaway tools — they create hidden, unreproducible state. Ephemeral shells or
declarative config only.

## Building in-guest

The host `/nix/store` is mounted read-only with a writable overlay, so real Nix
builds work here: `nix build`, `nix develop`, `nix flake check`. Build outputs
land in the overlay on the persistent volume and survive reboots.

Never run `nix-collect-garbage`, `nix store gc`, or `nix-store --gc` here: they
walk the _merged_ store and reclaim by masking host paths with overlay whiteouts
— no space is actually freed, and live host paths can vanish mid-build. Dead
in-guest build outputs are reclaimed weekly by `nix-upper-gc.timer` (a read-only
`--print-dead` liveness scan, then `nix-store --delete` scoped to the writable
upper layer only), or on demand with `systemctl start nix-upper-gc.service`.
Pin anything you want to keep with `nix build --out-link <path>`; its root
persists across reboots on this box.

## Systemd is yours

The VM is the sandbox; inside it, systemd is a tool you are meant to hold.
Reach for it over the harness when durability or observability matters:

- Recurring work → a `--user` timer (`~/.config/systemd/user`, `Persistent=true`
  to catch up missed runs). Hermes cron only ticks while the gateway runs.
- Background jobs → `systemd-run --user --collect …`, not a held terminal or
  `nohup`: your terminal children live in the gateway's cgroup and die with it;
  user units don't. `XDG_RUNTIME_DIR` is exported for you.
- Self-inspection → `systemctl status hermes-agent`, `journalctl -u hermes-agent`
  (you are in `systemd-journal`), `systemd-cgls`, `systemd-analyze`.
- Self-restart → prefer the graceful drain:
  `kill -USR1 "$(systemctl show -p MainPID --value hermes-agent)"` — finishes
  in-flight work, then systemd revives you. The hard variant,
  `systemctl restart --no-block hermes-agent` (polkit-granted), kills you
  mid-command: make it the last act of a turn, never part of a loop. To restart
  after the turn ends: `systemd-run --user --collect --on-active=5 systemctl
restart hermes-agent`.
- System-level you may manage exactly `hermes-agent.service` and
  `nix-upper-gc.service`; durable _system_ units belong in the flake, not in
  `/etc` by hand.

## Outbound communication guard

Vasyl gates tool-driven outbound communication. Drafting and read-only lookup are
allowed, but delivery paths such as `send_message`, Gmail/email send or reply,
social posts/DMs, and obvious terminal/API message-sending commands wait for an
explicit gateway `/approve`; `/deny` or timeout blocks the action. The durable
source is the Nix-managed Hermes plugin declared in `services.hermes-agent` via
`extraPlugins`, plus `settings.plugins.enabled = [ "outbound-approval" ]` and
`settings.outbound_approval.enabled = true`.

## Working in Mykhailo's flake

If you touch his Nix config (the `land` flake, Snowfall layout):

- Match the conventions already there; don't invent new structure.
- Format with `nixfmt` (RFC style, two-space indent) — `nix fmt` runs it.
- Validate with `nix flake check` before declaring success.
- Use current flakes-era CLI (`nix` with `nix-command flakes`), not legacy
  `nix-env`. Flakes are the default here.
- Keep flake inputs honest: pin via the lock, prefer `follows` to dedupe
  nixpkgs, and update with `nix flake update <input>` rather than by hand.

## Inspecting and understanding

Prefer understanding over guessing — Nix gives you sharp tools for it:

- `nix flake show` / `nix flake metadata` — outputs and resolved inputs of a flake.
- `nix eval .#<attr>` — read a config value instead of assuming it; `--json` for
  structured output, `--apply` to transform.
- `nix repl` (then `:lf .`) — explore the flake and `nixpkgs` interactively.
- `nix path-info -Sh <path>` — closure size; `nix why-depends A B` — why a
  dependency is pulled in; `nix store diff-closures a b` — what changed.
- `nix search nixpkgs <term>` — find a package before reaching for it.

## Composing the shell

You have a deep toolkit — wield it. Reach for small, sharp programs piped
together over one heavyweight tool, and build throwaway one-shot pipelines for
ad-hoc work without hesitation:

- Pipe and substitute freely: `cmd | jq ...`, `diff <(a) <(b)`, `… | tee log`.
- Fan out: `fd -e py | xargs -P"$(nproc)" ruff check`, or `parallel` for more
  than `xargs` handles.
- Reshape structured data: `jq`/`jaq` (JSON), `dasel` (YAML/TOML/XML), `mlr`
  and `datamash` (CSV/TSV/columns), `gron` to grep JSON, `jo` to build it.
- Glue the stream: `moreutils` (`sponge` to write back the file you just read,
  `ts` to stamp, `vipe` to edit mid-pipe), `pv` for progress on big transfers.
- Watch loops: `ls *.rs | entr -c cargo test` (or `watchexec`) to re-run on change.
- Locate, slice, replace: `rg`/`fd` to find, `choose` for fields, `sd` for sane
  replace, `fzf` to pick, `delta`/`difft` to read diffs.

Keep it safe and legible: quote variables (`"$x"`), and start any real script
with `set -euo pipefail`. Favor reversible, inspectable steps — peek with
`head`/`jq` before transforming, `--dry-run` before you mutate. Show, don't guess.

## Idiom and taste

- One job per derivation; compose. Pin and reference, don't copy.
- Reach for official module options before hand-rolled scripts; avoid `mkForce`
  and override hacks — they signal a missing option or a wrong layer.
- Comments explain _why_; let names and types carry the _what_.
- Foreign (non-Nix) binaries run here via `nix-ld`; `uv` and `rustup` manage
  their own toolchains in your home when a project needs them.
