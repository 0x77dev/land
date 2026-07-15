---
alwaysApply: true
---

# Contributing

This repository uses [Snowfall Lib] to manage Nix configurations
for NixOS and Darwin systems.

## Structure

The repository follows [Snowfall Lib]'s conventional directory structure:

```tree
nix/
├── lib/              # Custom library functions
├── modules/          # NixOS and Darwin modules
│   ├── darwin/       # Darwin-specific modules
│   └── nixos/        # NixOS-specific modules
├── overlays/         # Package overlays
├── packages/         # Custom packages
├── shells/           # Development shells
├── systems/          # System configurations
│   ├── aarch64-darwin/
│   ├── aarch64-linux/  # Raspberry Pi, ARM SBCs
│   └── x86_64-linux/
└── homes/            # Home Manager configurations
    ├── aarch64-darwin/
    ├── aarch64-linux/
    └── x86_64-linux/
```

## Channels

This flake uses two nixpkgs channels:

- **nixpkgs** (nixos-26.05): Stable channel for primary packages
- **unstable** (nixpkgs-unstable): Rolling release for bleeding-edge packages

## Overlays

### Unstable Overlay

Packages from the unstable channel should be added to
`nix/overlays/unstable/default.nix` using the `inherit` keyword:

```nix
{ channels, ... }:
final: prev:
{
  inherit (channels.unstable)
    ghostty
    # Add more unstable packages here
    ;
}
```

This makes unstable packages available throughout the configuration
via `pkgs.ghostty` without explicitly prefixing with a namespace.

All NVIDIA userspace tooling (CUDA, `nvtopPackages`,
`nvidia-container-toolkit`) is routed from unstable here. The same overlay
pins `cudaPackages`/`cudatoolkit` to a single CUDA version (`cudaPackages_12_9`)
as the single source of truth, so every host stays on the same toolkit. Per-GPU
`cudaCapabilities` and the kernel-matched `hardware.nvidia.package` driver stay
in the host configs.

### Custom Overlays

Create new overlays in `nix/overlays/<name>/default.nix`.
Each overlay follows the pattern:

```nix
{ channels, ... }:
final: prev:
{
  # Your overlay definitions
}
```

## Modules

Modules are automatically loaded based on the platform:

- Darwin modules: `nix/modules/darwin/<name>/default.nix`
- NixOS modules: `nix/modules/nixos/<name>/default.nix`

All modules are automatically applied to matching system types.

### Hardware Modules

Hardware-specific support lives in `nix/modules/nixos/hardware/<name>/`. Each is
an option-driven module that a system opts into with a single flag. For example,
the `dgx-spark` module (NVIDIA DGX Spark / GB10: CUDA `sm_121`, the out-of-tree
NVIDIA driver + container toolkit, the `arm64.nobti` workaround, fwupd, Flox CUDA
cache — on stock mainline, no custom kernel) is enabled with
`hardware.dgx-spark.enable = true;`, as used by the `spark` system.

## Library Functions

Custom library functions should be placed in `nix/lib/`
and will be available under the `land` namespace as `lib.land.<function-name>`.

## Deployment

### nixos-anywhere

Initial system provisioning uses [nixos-anywhere] to remotely install NixOS:

```bash
nixos-anywhere --flake .#muscle root@target-ip
```

Handles disk partitioning (via disko), installation, and initial configuration.

[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere

## Linting and Validation

This repository uses automated linting and validation to maintain code quality
and consistency. Two complementary tools handle this:

### Pre-commit Hooks (prek)

Git hooks are managed via [prek](https://github.com/j178/prek), a Rust-based
re-implementation of pre-commit that's faster and more reliable than the original
Python implementation.

**Configuration**: `nix/lib/git-hooks/`

**Running hooks manually**:

```bash
# Run all hooks on all git-tracked files
prek run -a

# Run all hooks on changed files only
prek run

# Run specific hook
prek run treefmt
```

**Important**: `prek` only processes **git-tracked files**. If you're working with
new files that haven't been staged yet, you must `git add` them first:

```bash
# Stage new files so prek can validate them
git add .
prek run -a
```

Hooks run automatically on `git commit`. To bypass hooks temporarily (not recommended):

```bash
git commit --no-verify
```

### Flake Validation

For comprehensive validation of the entire flake configuration:

```bash
# Validate all flake outputs (builds in sandbox)
nix flake check

# Validate specific system
nix flake check --all-systems -L
```

**Note**: `nix flake check` runs in a sandbox with:

- No internet access
- Read-only filesystem
- Complete isolation

This makes it ideal for CI/CD but may not catch all local development issues.
Always run `prek run -a` before committing to ensure local files are validated.

### Development Workflow

Recommended validation workflow:

```bash
# 1. Stage your changes
git add .

# 2. Run pre-commit hooks on all files
prek run -a

# 3. If prek modified files, stage them again
git add .

# 4. Validate the entire flake
nix flake check
```

## Automation and Updates

### GitHub Actions

CI evaluates the complete flake and builds every package, shell, system, and
home closure on a native GitHub-hosted runner. Flake inputs update through one
validated pull request and use native auto-merge after required checks pass.
CodeQL analyzes GitHub Actions and Python on every change, then OpenSSF
Scorecard publishes default-branch results after CodeQL succeeds.

Spelling is checked by
[typos](https://github.com/crate-ci/typos) via the pre-commit hooks, with
exceptions kept minimal in `_typos.toml`.

## Adding Packages

1. For custom packages, create a directory in `nix/packages/<name>/default.nix`
2. For packages from unstable, add them to the unstable overlay
3. Packages are automatically exported and available in all configurations

## Documentation Standards

### Single Source of Truth

**Never duplicate information.** Each piece of information must exist in
exactly one canonical location:

- **README.md** - Project overview, quick start, philosophy
- **CONTRIBUTING.md** - Development workflow, structure, contribution guidelines
- **Code comments** - Implementation details, "why" not "how"
- **Module files** - Self-documenting through clear names and structure

### Documentation Update Requirements

**All changes that affect user-facing behavior MUST update documentation
before merge:**

1. **Code changes** - Update affected documentation in the same commit
2. **New features** - Add to README.md features list if user-visible
3. **Structure changes** - Update CONTRIBUTING.md structure section
4. **New dependencies** - Document in README.md Technology Stack
5. **Breaking changes** - Update Quick Start section with migration notes

**Violation of this requirement will result in PR rejection.**

### Minimalism Principle

Documentation should be:

- **Essential only** - If users can figure it out from code/types,
  don't document it
- **Actionable** - Every sentence must serve a purpose
- **Tested** - All commands and examples must be verified before commit
- **Current** - Delete outdated docs immediately, don't mark as deprecated

### When to Document

Document when:

- Behavior is non-obvious from code
- Design decisions need rationale
- External integrations require setup
- Security implications exist

Don't document:

- Self-evident code (well-named functions don't need comments)
- Temporary workarounds (fix the code instead)
- Implementation details that change frequently
- Information derivable from types or signatures

## Code Style

See [nixpkgs formatting guidelines][nixpkgs-style] for comprehensive
style rules.

Project-specific requirements:

- 2-space indentation (enforced by treefmt via `nixfmt`; run `nix fmt`)
- Verb-first function naming: `mkPackage`, `buildConfig`
- Use `lib.land` namespace for custom functions
- Modules named by concern, not implementation

[Snowfall Lib]: https://snowfall.org/
[nixpkgs-style]: https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md
