# land

[![NixOS 25.05][nixos-badge]][nixos]
[![nix-darwin 25.05][nix-darwin-badge]][nix-darwin]
[![Home Manager][home-manager-badge]][home-manager]
[![Snowfall Lib][snowfall-badge]][snowfall-lib]
[![Chores][chores-badge]][chores]
[![License: WTFPL][license-badge]][wtfpl]
[![Maintained][maintained-badge]][commits]

Declarative system configurations using [Nix flakes][nix-flakes],
managed with [Snowfall Lib][snowfall-lib].

## Philosophy

This repository embodies three core principles:

**Reproducibility** - Every system component is declaratively defined in
version control. The same configuration produces identical results across
rebuilds and machines. Flake lock files ensure dependency versions are
pinned, eliminating "works on my machine" issues.

**Automatic Inference** - [Snowfall Lib][snowfall-lib] automatically discovers
and wires flake outputs from the directory structure. Modules, packages, and
overlays are loaded based on convention, reducing boilerplate and manual
configuration.

**Distributed Builds** - Build machines are automatically configured for
cross-platform compilation. Darwin systems can build Linux packages via the
Linux builder, and x86_64 systems can build aarch64 packages through remote
builders.

## Scope

This configuration manages:

- **Darwin (macOS)** - System configuration via [nix-darwin][nix-darwin]
- **NixOS (Linux)** - Server configurations
- **Home Manager** - User environments and dotfiles
- **Secrets** - Encrypted with [sops-nix][sops-nix] using SSH host keys
- **Packages** - Custom derivations and unstable channel overlays

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Git for cloning the repository
- Basic familiarity with Nix and the command line

### Darwin (macOS)

**Initial installation:**

```bash
# Clone repository
git clone https://github.com/0x77dev/land.git
cd land

# First-time build requires sandbox disabled due to macOS limitations
sudo nix run nix-darwin --experimental-features 'nix-command flakes' -- \
  switch --flake .#potato --option sandbox false
```

**Note:** The sandbox must be disabled for the initial build on macOS due to
a 64KB parameter limit. Subsequent rebuilds work normally.

**Subsequent updates:**

```bash
cd /path/to/land
git pull
darwin-rebuild switch --flake .#potato
```

### NixOS

```bash
# Clone repository
git clone https://github.com/0x77dev/land.git
cd land

# Apply configuration
sudo nixos-rebuild switch --flake .#muscle
```

The repository follows [Snowfall Lib's directory structure][snowfall-structure],
which organizes Nix files by purpose (modules, packages, systems, etc.) for
automatic discovery and loading.

## Systems

| Hostname | Platform | Description |
|----------|----------|-------------|
| `potato` | `aarch64-darwin` | Primary macOS workstation |
| `muscle` | `x86_64-linux` | NixOS server |

## Technology Stack

### Core Infrastructure

- [Nix][nix] (Lix 2.91) - Package manager and build system
- [NixOS 25.05][nixos] - Linux distribution
- [nix-darwin 25.05][nix-darwin] - macOS system configuration
- [Home Manager][home-manager] (25.05) - User environment
- [Snowfall Lib][snowfall-lib] - Flake organization framework

### Tooling & Integration

- [sops-nix][sops-nix] - Secrets management with age encryption
- [nix-homebrew][nix-homebrew] - Declarative Homebrew management
- [prek][prek] - Fast pre-commit hook runner (Rust-based)
- [git-hooks.nix][git-hooks] - Pre-commit hooks

### Package Sources

- nixpkgs (stable: 25.05, unstable: rolling)
- Custom packages: TX-02 Variable font, UA Connect

## Features

- **Modular Organization** - Separate concerns (shell, security, IDE, media,
  etc.)
- **DRY Configuration** -
  Shared settings via `lib.land.shared.*` functions
- **Platform-Aware Packages** -
  Automatic selection (ghostty-bin on macOS, code-cursor-fhs on Linux)
- **Automatic Builds** -
  Cross-compilation via remote builders and Linux builder VM
- **Security Hardening** - Touch ID sudo, login window restrictions, SSH key management

## Development

```bash
# Enter development shell (includes pre-commit hooks)
nix develop

# Run hooks manually
pre-commit run --all-files

# Update flake inputs
nix flake update
```

Development shell provides:

- Quality tools: nixfmt-rfc-style, deadnix, statix, shellcheck
- Documentation linters: markdownlint, mdsh, cspell
- Security scanners: trufflehog
- Secrets tools: sops, age, ssh-to-age

## Contributing

See [CONTRIBUTING.md][contributing] for detailed guidelines on:

- Repository structure and Snowfall Lib conventions
- Nix language best practices
- Secrets management workflow
- Code style and formatting standards

## License

This work is licensed under the [WTFPL][wtfpl]
(Do What The Fuck You Want To Public License).

<!-- Badge References -->
[nixos-badge]: https://img.shields.io/badge/NixOS-25.05-blue.svg?style=flat&logo=nixos&logoColor=white
[nix-darwin-badge]: https://img.shields.io/badge/nix--darwin-25.05-blue.svg?style=flat&logo=apple&logoColor=white
[home-manager-badge]: https://img.shields.io/badge/home--manager-25.05-blue.svg?style=flat&logo=nixos&logoColor=white
[snowfall-badge]: https://img.shields.io/badge/built%20with-snowfall-blue?style=flat
[license-badge]: https://img.shields.io/badge/License-WTFPL-blue.svg?style=flat
[maintained-badge]: https://img.shields.io/badge/maintained-yes-success.svg?style=flat
[chores-badge]: https://github.com/0x77dev/land/actions/workflows/chores.yaml/badge.svg

<!-- Project Links -->
[commits]: https://github.com/0x77dev/land/graphs/commit-activity
[contributing]: /CONTRIBUTING.md
[wtfpl]: /LICENSE
[chores]: https://github.com/0x77dev/land/actions/workflows/chores.yaml

<!-- Technology Links -->
[nix]: https://nixos.org/manual/nix/stable/
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nixos]: https://nixos.org
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[snowfall-lib]: https://snowfall.org
[sops-nix]: https://github.com/Mic92/sops-nix
[nix-homebrew]: https://github.com/zhaofengli/nix-homebrew
[prek]: https://prek.j178.dev
[git-hooks]: https://github.com/cachix/git-hooks.nix
[snowfall-structure]: https://snowfall.org/reference/lib/#flake-structure
