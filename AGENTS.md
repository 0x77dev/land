# Repository guidance

## Start here

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing the repository; it is
  canonical for placement, validation, and documentation ownership.
- Load the `snowfall-nix` project skill for Nix or Snowfall Lib work, then
  inspect the nearest analogous component and the revisions in `flake.lock`.
- Use `direnv exec . <command>` or `nix develop -c <command>` rather than
  installing host tools. `.envrc` loads the ignored `.env`; never inspect,
  commit, or copy its secrets into Nix values.

## Snowfall boundaries

- Snowfall discovers `default.nix` components below `nix/`; do not add manual
  imports or flake outputs for internal packages, overlays, modules, systems,
  homes, shells, or libraries.
- Matching modules under `nix/modules/{nixos,darwin,home}` apply to every
  matching configuration. Gate optional behavior with an enable option.
- Keep `flake.nix` for inputs, external module attachment, channel-wide policy,
  and genuinely global output wiring. Existing exceptions are deliberate.
- Use Snowfall-supplied `pkgs`, `lib`, `inputs`, and `namespace`; do not import
  another nixpkgs instance without a demonstrated package-set boundary.
- Stable nixpkgs is primary. Promote selected unstable packages through
  `nix/overlays/unstable/default.nix`; custom packages and libraries are
  available as `pkgs.land.<name>` and `lib.land.<name>`.
- Do not hand-maintain CI target lists: `nix/lib/automation/default.nix` derives
  checks and native system/home closures from discovered flake outputs.

## Verification

- Format only touched paths with `nix fmt -- <paths>`, then run
  `prek run --files <paths>`. Before completion, use `prek run -a` and
  `nix flake check` when the change's scope warrants the full repository checks.
- Evaluate a focused NixOS host with
  `nix eval --raw .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`;
  Darwin uses `nix eval --raw .#darwinConfigurations.<host>.system.drvPath`, and
  Home Manager uses
  `nix eval --raw '.#homeConfigurations."<user>@<host>".activationPackage.drvPath'`.
- Build a changed custom package through its CI check with
  `nix build --no-link .#checks.<system>.package-<name>`. Build an affected
  host/home target without its trailing `.drvPath` when closure proof is needed.
- `prek` and normal Git-backed flake evaluation ignore untracked files. Validate
  new files from a temporary Git-filtered copy; never use `path:.` in a working
  tree with ignored secrets or alter the index without permission.
- Do not update `flake.lock` unless the requested change alters inputs. The
  scheduled workflow updates all inputs together and validates the lock-only PR.

## Operations and policy

- `just provision` runs `nixos-anywhere` and may repartition a target. Do not
  provision, rebuild, activate, or deploy unless explicitly requested.
- Cachix Deploy is sourced from `nix/deploy/default.nix`; `vasyl` is part of
  `spark`'s atomic microVM closure, not a separate deployment agent.
- Keep credentials and host-local state outside the Nix store and repository;
  follow the relevant `docs/` runbook for security-sensitive integrations.
- Update the canonical documentation in the same change for user-facing
  behavior, but do not duplicate facts across README, CONTRIBUTING, and docs.
- Preserve unrelated work. Do not commit or publish changes unless explicitly
  asked.
