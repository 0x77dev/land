# land

[![NixOS][nixos-badge]][nixos]
[![nix-darwin][nix-darwin-badge]][nix-darwin]
[![Home Manager][home-manager-badge]][home-manager]
[![Snowfall Lib][snowfall-badge]][snowfall-lib]
[![ci][ci-badge]][ci]
[![License: WTFPL][license-badge]][wtfpl]
[![Maintained][maintained-badge]][commits]

Declarative infrastructure using [Nix flakes][nix-flakes] and
[Snowfall Lib][snowfall-lib].

## Architecture

**Reproducibility** - Declarative configuration with pinned dependencies.
Identical builds across machines and environments.

**Convention over Configuration** - [Snowfall Lib][snowfall-lib] infers
outputs from directory structure. Minimal boilerplate.

**Distributed Builds** - Cross-platform compilation configured automatically.
Darwin builds Linux, x86_64 builds aarch64.

## Scope

- **Darwin** - System configuration via [nix-darwin][nix-darwin]
- **NixOS** - Server and workstation configurations
- **WSL 2** - NixOS on Windows with GPU passthrough
- **Home Manager** - User environments and dotfiles
- **Secrets** - [sops-nix][sops-nix] with SSH host keys
- **Packages** - Custom derivations and unstable overlays

## Deployment

Deployments use [deploy-rs][deploy-rs] with automatic configuration generation.
All systems are deployed from a single flake with zero manual configuration.

### Initial Provisioning

Bootstrap new systems remotely with [nixos-anywhere][nixos-anywhere]:

```bash
# NixOS systems (handles disk partitioning and installation)
nixos-anywhere --flake .#pickle nixos@<host>
nixos-anywhere --flake .#tomato nixos@<host>

# Darwin requires manual initial setup (see below)
```

### Ongoing Updates

Deploy from development shell:

```bash
nix develop

# Deploy to specific system
deploy .#pickle
deploy .#tomato
deploy .#potato

# Deploy to all systems
deploy .
```

### Darwin Bootstrap

Initial setup requires sandbox disabled on macOS:

```bash
git clone https://github.com/0x77dev/land.git
cd land
sudo nix run nix-darwin --experimental-features 'nix-command flakes' -- \
  switch --flake .#potato --option sandbox false
```

After initial setup, use `deploy .#potato` for updates.

### WSL 2

Requirements: Windows 11, WSL 2.4.4+, NVIDIA driver for GPU support.

Setup WSL:

```powershell
wsl --install --no-distribution
wsl --update
```

Build tarball:

```bash
nix build github:0x77dev/land#nixosConfigurations.wsl.config.system.build.tarballBuilder
sudo ./result/bin/nixos-wsl-tarball-builder
```

Import to Windows:

```powershell
wsl --import wsl $env:USERPROFILE\wsl <result> --version 2
wsl -d wsl
```

Verify GPU:

```bash
nvidia-smi
docker run --rm --device=nvidia.com/gpu=all \
  nvcr.io/nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

## Systems

| Host | Platform | Role | Specs |
| ------ | ---------- | ------ | ------- |
| `potato` | `aarch64-darwin` | Workstation | M4 Max, 48GB |
| `tomato` | `x86_64-linux` | Homelab | MS-01, i9-13900H, 96GB |
| `pickle` | `x86_64-linux` | Homelab | MS-01, i9-13900H, 96GB |
| `beefy` | `aarch64-darwin` | Media | M2 Ultra, 64GB |
| `muscle` | `x86_64-linux` | AI/Compute | TR 7985WX, RTX6000, 250GB |
| `wsl` | `x86_64-linux` | AI/Compute (WSL) | TR 7985WX, RTX6000, 250GB |
| `shadow` | `x86_64-linux` | Fun | T480, 16GB |

## Stack

[Nix][nix] ([Lix][lix]), [NixOS][nixos], [nix-darwin][nix-darwin],
[Home Manager][home-manager], [Snowfall Lib][snowfall-lib],
[sops-nix][sops-nix], [NixOS-WSL][nixos-wsl], [deploy-rs][deploy-rs],
[nixos-anywhere][nixos-anywhere]

## Development

```bash
nix develop
nix flake check
nix flake update
```

See [CONTRIBUTING.md][contributing] for conventions.

## License

[WTFPL][wtfpl]

<!-- Badge References -->
[nixos-badge]: https://img.shields.io/badge/NixOS-blue.svg?style=flat&logo=nixos&logoColor=white
[nix-darwin-badge]: https://img.shields.io/badge/nix--darwin-blue.svg?style=flat&logo=apple&logoColor=white
[home-manager-badge]: https://img.shields.io/badge/home--manager-blue.svg?style=flat&logo=nixos&logoColor=white
[snowfall-badge]: https://img.shields.io/badge/built%20with-snowfall-blue?style=flat
[license-badge]: https://img.shields.io/badge/License-WTFPL-blue.svg?style=flat
[maintained-badge]: https://img.shields.io/badge/maintained-yes-success.svg?style=flat
[ci-badge]: https://github.com/0x77dev/land/actions/workflows/ci.yaml/badge.svg

<!-- Project Links -->
[commits]: https://github.com/0x77dev/land/graphs/commit-activity
[contributing]: /CONTRIBUTING.md
[wtfpl]: /LICENSE
[ci]: https://github.com/0x77dev/land/actions/workflows/ci.yaml

<!-- Technology Links -->
[nix]: https://nixos.org/manual/nix/stable/
[lix]: https://lix.systems
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nixos]: https://nixos.org
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[snowfall-lib]: https://snowfall.org
[sops-nix]: https://github.com/Mic92/sops-nix
[nixos-wsl]: https://github.com/nix-community/NixOS-WSL
[deploy-rs]: https://github.com/serokell/deploy-rs
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
