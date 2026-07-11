# Snowfall Lib reference

## Resolve the current contract

Treat `flake.nix` and `flake.lock` as the source of truth for the Snowfall root,
namespace, supported systems, and library revision. When upstream behavior
matters, inspect the locked Snowfall source rather than assuming the latest
documentation matches it. Preserve the existing generated-output layering
instead of rebuilding Snowfall outputs manually.

## Discovery map

`CONTRIBUTING.md` owns placement. After a component is placed there, Snowfall
discovers its `default.nix` and maps it to outputs:

- `nix/packages/<name>/` becomes `packages.<system>.<name>` and is available
  through the internal package overlay as `pkgs.land.<name>`.
- `nix/overlays/<name>/` becomes an overlay and is applied to the flake's
  package sets.
- `nix/modules/{nixos,darwin,home}/<name>/` becomes a platform module and is
  applied to matching configurations.
- `nix/systems/<target>/<host>/` becomes a system configuration.
- `nix/homes/<target>/<user>@<host>/` becomes a Home Manager configuration.
- `nix/shells/<name>/` becomes `devShells.<system>.<name>`.
- `nix/lib/<name>/` is merged into `lib.land`.

Nested component names follow their directory structure. Prefer one
concern-named directory over unrelated definitions in a shared catch-all file.

## Supplied arguments

Use the arguments supplied by Snowfall and the module system:

- Packages: Nixpkgs `callPackage` arguments plus `lib`, `inputs`, `namespace`,
  and `pkgs`.
- Overlays: a leading set containing `channels`, `inputs`, `lib`, and
  `namespace`, followed by `final: prev:`.
- Modules: `config`, `lib`, `pkgs`, `inputs`, `namespace`, and target metadata
  such as `system`, `target`, `format`, and `host`.
- Libraries: `lib`, `inputs`, `snowfall-inputs`, and `namespace`.

Accept `...` only when the component intentionally ignores additional supplied
arguments. Do not import another Nixpkgs instance inside a component; that
bypasses overlays, channel policy, and package consistency.

## Global wiring

Use `flake.nix` only when the change cannot be discovered from `nix/`:

- Add or pin a flake input.
- Attach an external module to all systems of one platform.
- Attach an external module or `specialArgs` to one host or home.
- Configure channel-wide Nixpkgs policy.
- Add a genuinely generic output through `outputs-builder`.
- Add an output alias.

Keep inputs following the intended Nixpkgs channel unless the input documents a
reason not to do so. Existing exceptions in `flake.nix` are deliberate.

## Common failures

- Missing output: verify the target directory and `default.nix` name before
  adding manual wiring.
- Package visible in flake outputs but not `pkgs`: access internal packages
  through `pkgs.land`, or use the unstable overlay for promoted channel
  packages.
- Module option has no effect: verify the module platform and its enable
  condition, then inspect the matching system or home.
- Evaluation uses the wrong package version: inspect the applied overlays and
  channel before adding an override.
- New file absent from a flake evaluation: Nix flakes only include files known
  to Git; stage the file only when the user has authorized staging.

## Upstream references

- [Snowfall Lib guide](https://snowfall.org/guides/lib/quickstart/)
- [Snowfall Lib reference](https://snowfall.org/reference/lib/)
- [Snowfall Lib source](https://github.com/snowfallorg/lib)
