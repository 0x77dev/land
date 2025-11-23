# land

[![NixOS][nixos-badge]][nixos]
[![nix-darwin][nix-darwin-badge]][nix-darwin]
[![Home Manager][home-manager-badge]][home-manager]
[![Incus][incus-badge]][incus]
[![Snowfall Lib][snowfall-badge]][snowfall-lib]
[![sops-nix][sops-nix-badge]][sops-nix]
[![deploy-rs][deploy-rs-badge]][deploy-rs]
[![nixos-anywhere][nixos-anywhere-badge]][nixos-anywhere]
[![ci][ci-badge]][ci]
[![License: WTFPL][license-badge]][wtfpl]
[![Maintained][maintained-badge]][commits]

Declarative infrastructure using [Nix flakes][nix-flakes] and
[Snowfall Lib][snowfall-lib].

## Deployment

Deployments use [deploy-rs][deploy-rs] with automatic configuration generation.
All systems are deployed from a single flake with zero manual configuration.

### Initial Provisioning

Build an ISO:

```bash
nom build .#isoConfigurations.installer -o result-installer
ls ./result-installer
```

Bootstrap new systems remotely with [nixos-anywhere][nixos-anywhere]:

```bash
# NixOS systems (handles disk partitioning and installation)
nixos-anywhere --flake .#pickle nixos@<host>
nixos-anywhere --flake .#tomato nixos@<host>

# Darwin requires manual initial setup (see below)

# SBC/Raspberry Pi (build SD card image and flash)
# See /docs/SBC-IMAGE-BUILD.md for detailed instructions
nix build '.#nixosConfigurations.melon.config.system.build.sdImage'
```

### Ongoing Updates

Deploy from development shell:

```bash
nix develop

# Deploy to specific system
deploy .#pickle -s --remote-build
deploy .#tomato -s --remote-build
deploy .#potato -s --remote-build

# Deploy to all systems
deploy . -s --remote-build
```

### Darwin Bootstrap

Initial setup requires sandbox disabled on macOS:

```bash
git clone https://github.com/0x77dev/land.git
cd land
sudo nix run nix-darwin --experimental-features 'nix-command flakes' -- \
  switch --flake .#potato --option sandbox false
```

After initial setup, use `deploy .#potato -s --remote-build` for updates.

## Systems

| Host | Platform | Role | Specs |
| ------ | ---------- | ------ | ------- |
| `potato` | `aarch64-darwin` | Workstation | M4 Max, 48GB |
| `tomato` | `x86_64-linux` | Homelab / Cluster | MS-01, i9-13900H, 96GB |
| `pickle` | `x86_64-linux` | Homelab / Cluster | MS-01, i9-13900H, 96GB |
| `melon` | `aarch64-linux` | IoT/Edge | RPi 4B, 4GB+, PoE |
| `beefy` | `aarch64-darwin` | Media | M2 Ultra, 64GB |
| `muscle` | `x86_64-linux` | AI/Compute | TR 7985WX, RTX6000, 250GB |
| `shadow` | `x86_64-linux` | Fun | T480, 16GB |

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
[incus-badge]: https://img.shields.io/badge/Incus-333.svg?style=flat&logo=linuxcontainers&logoColor=DE4714
[snowfall-badge]: https://img.shields.io/badge/built%20with-snowfall-blue?style=flat&logo=nix&logoColor=white
[sops-nix-badge]: https://img.shields.io/badge/sops--nix-blue.svg?style=flat
[deploy-rs-badge]: https://img.shields.io/badge/deploy--rs-blue.svg?style=flat
[nixos-anywhere-badge]: https://img.shields.io/badge/nixos--anywhere-blue.svg?style=flat
[license-badge]: https://img.shields.io/badge/License-WTFPL-blue.svg?style=flat
[maintained-badge]: https://img.shields.io/badge/maintained-yes-success.svg?style=flat
[ci-badge]: https://github.com/0x77dev/land/actions/workflows/ci.yaml/badge.svg

<!-- Project Links -->
[commits]: https://github.com/0x77dev/land/graphs/commit-activity
[contributing]: /CONTRIBUTING.md
[wtfpl]: /LICENSE
[ci]: https://github.com/0x77dev/land/actions/workflows/ci.yaml

<!-- Technology Links -->
[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nixos]: https://nixos.org
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[snowfall-lib]: https://snowfall.org
[sops-nix]: https://github.com/Mic92/sops-nix
[deploy-rs]: https://github.com/serokell/deploy-rs
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
[incus]: https://linuxcontainers.org/incus
