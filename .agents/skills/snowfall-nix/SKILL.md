---
name: snowfall-nix
description: Guides changes to this repository's Snowfall Lib Nix flake, including packages, overlays, modules, systems, homes, and checks. Use when editing flake.nix or files under nix/, adding Nix dependencies, or debugging Nix evaluation and build failures.
---

# Snowfall Nix

Use the repository's existing Snowfall Lib architecture. Do not replace it with
generic `flake-utils`, hand-built output matrices, or ad hoc import lists.

## Workflow

1. Read `AGENTS.md` and `CONTRIBUTING.md`.
2. Inspect `flake.nix`, `flake.lock`, and the nearest analogous file.
3. Put the change in the narrowest Snowfall-managed location.
4. Keep `flake.nix` limited to inputs and genuinely global output wiring.
5. Format and run the smallest check that proves the change, then broaden
   verification in proportion to its impact.

## Placement

`CONTRIBUTING.md` owns the repository layout and placement policy. Snowfall
discovers the documented `nix/` component directories automatically; do not add
manual imports merely to register a package, module, overlay, shell, system, or
home. Change `flake.nix` only for external inputs, global output wiring, or
external module attachment that Snowfall cannot discover.

## Repository conventions

- The Snowfall root is `./nix`; the namespace is `land`.
- Stable `nixpkgs` is primary. Export intentionally selected unstable packages
  through `nix/overlays/unstable/default.nix`.
- Add external modules globally by platform or to one host/home in
  `lib.mkFlake`; keep internal modules option-driven where practical.
- Use explicit function arguments and the arguments Snowfall supplies instead
  of re-importing `nixpkgs`.
- Preserve the existing supported-system set and package checks unless the task
  explicitly changes platform support.
- Never expose credentials through flake inputs, skill files, derivation text,
  or values that enter the Nix store.

## Verification

Prefer a narrow evaluation or build for the affected output before the full
flake check. Follow `CONTRIBUTING.md` for canonical formatting, hook, and flake
validation commands. Do not update `flake.lock` unless the requested change
alters inputs.

Read [references/snowfall-lib.md](references/snowfall-lib.md) when adding a new
Snowfall-managed component, changing output construction, or diagnosing
discovery and namespace behavior.
