# land

[![NixOS][nixos-badge]][nixos]
[![nix-darwin][nix-darwin-badge]][nix-darwin]
[![Home Manager][home-manager-badge]][home-manager]
[![Snowfall Lib][snowfall-badge]][snowfall-lib]
[![nixos-anywhere][nixos-anywhere-badge]][nixos-anywhere]
[![License: WTFPL][license-badge]][wtfpl]
[![Maintained][maintained-badge]][commits]

Declarative infrastructure using [Nix flakes][nix-flakes] and
[Snowfall Lib][snowfall-lib].

## Deployment

All systems are built from a single flake. Initial provisioning uses
[nixos-anywhere][nixos-anywhere]; ongoing updates use `nixos-rebuild`.

### Initial Provisioning

Build an ISO:

```bash
nom build .#isoConfigurations.installer -o result-installer
ls ./result-installer
```

Bootstrap new systems remotely with [nixos-anywhere][nixos-anywhere]:

```bash
# NixOS systems (handles disk partitioning and installation)
nixos-anywhere --flake .#tomato nixos@<host>
nixos-anywhere --flake .#muscle nixos@<host>

# Darwin requires manual initial setup (see below)

# SBC/Raspberry Pi (build SD card image and flash)
# See /docs/SBC-IMAGE-BUILD.md for detailed instructions
nix build '.#nixosConfigurations.melon.config.system.build.sdImage'
```

### Flashing eMMC via rpiboot

For Compute Modules or devices with eMMC (like `timey`), use
[`rpiboot`](https://www.raspberrypi.com/documentation/computers/compute-module.html)
to mount the storage:

1. Connect device via USB slave port (ensure USB boot jumper/switch is set).

2. Run `rpiboot` (available in dev shell):

   ```bash
   sudo rpiboot
   ```

3. Flash the image to the exposed block device (e.g. `/dev/sda`):

   ```bash
   nix build '.#nixosConfigurations.timey.config.system.build.sdImage'
   zstdcat result/sd-image/nixos-sd-image-rpi5-kernel.img.zst | \
     sudo dd of=/dev/sdb bs=4M status=progress conv=fsync
   ```

### Ongoing Updates

```bash
# Rebuild a NixOS host (optionally over SSH with a remote build host)
just nixos-rebuild tomato mykhailo@<host>
```

### NixOS Bootstrap

```bash
nixos-rebuild switch -L --flake sourcehut:~dev0x77/land --refresh
```

### Darwin Bootstrap

Initial setup requires sandbox disabled on macOS:

```bash
sudo nix run nix-darwin --experimental-features 'nix-command flakes' -- \
  switch -L --flake sourcehut:~dev0x77/land --option sandbox false
```

Darwin activations refresh Homebrew taps with `brew update` and apply
upgrades with `brew upgrade` by default.

## Systems

| Host     | Platform         | Role              | Specs                     |
| -------- | ---------------- | ----------------- | ------------------------- |
| `potato` | `aarch64-darwin` | Workstation       | M4 Max, 48GB              |
| `tomato` | `x86_64-linux`   | Homelab / Cluster | MS-01, i9-13900H, 96GB    |
| `spark`  | `aarch64-linux`  | AI/Compute        | NVIDIA DGX Spark (GB10)   |
| `timey`  | `aarch64-linux`  | IoT/Edge/Time     | RPi 5, eMMC               |
| `beefy`  | `aarch64-darwin` | Media             | M2 Ultra, 64GB            |
| `muscle` | `x86_64-linux`   | AI/Compute        | TR 7985WX, RTX6000, 250GB |
| `ghost`  | `x86_64-linux`   | Fun               | T480, 16GB                |

## Development

```bash
nix develop
nix flake check
nix flake update
```

Managed hosts expose this flake's inputs through the system flake registry,
so pinned input references work directly, for example `nix shell unstable#grype`.

Darwin hosts offload `x86_64-linux` and `aarch64-linux` builds to
`muscle` via system-level Nix distributed builds. Use `nix build -j0`
when you want to force a Linux-target build onto the remote builder.

## Automation

GitHub Actions validates the flake on both Linux and Darwin, pushes
successful CI builds to `land.cachix.org`, and runs weekly security
checks with OpenSSF Scorecard plus `vulnix` across the native flake
closures inferred from declared outputs.

Dependency updates are managed weekly with Renovate. Non-major GitHub
Actions and flake lock maintenance updates are configured for automerge
after CI/security checks pass, while comment-annotated custom pinned
versions can be tracked through regex managers in [`renovate.json5`].

AI-enabled Home Manager profiles configure the terminal agent stack managed in
[`nix/modules/home/ai/`]. OpenCode is the agent runtime, with global skills and
Cursor/Neovim integrations managed declaratively. Model routing and OpenAI model
metadata overrides live in [`config/opencode.json`](/config/opencode.json).

Hardware-specific support lives in `nix/modules/nixos/hardware/`. Each is an
option-driven module (e.g. `hardware.dgx-spark.enable`) so a system opts in with
a single flag; the `spark` system uses the `dgx-spark` module.

See [CONTRIBUTING.md][contributing] for conventions.

## License

[WTFPL][wtfpl]

<!-- Badge References -->

[nixos-badge]: https://img.shields.io/badge/NixOS-blue.svg?style=flat&logo=nixos&logoColor=white
[nix-darwin-badge]: https://img.shields.io/badge/nix--darwin-blue.svg?style=flat&logo=apple&logoColor=white
[home-manager-badge]: https://img.shields.io/badge/home--manager-blue.svg?style=flat&logo=nixos&logoColor=white
[snowfall-badge]: https://img.shields.io/badge/built%20with-snowfall-blue?style=flat&logo=nix&logoColor=white
[nixos-anywhere-badge]: https://img.shields.io/badge/nixos--anywhere-blue.svg?style=flat
[license-badge]: https://img.shields.io/badge/License-WTFPL-blue.svg?style=flat
[maintained-badge]: https://img.shields.io/badge/maintained-yes-success.svg?style=flat

<!-- Project Links -->

[commits]: https://git.sr.ht/~dev0x77/land/log
[contributing]: /CONTRIBUTING.md
[wtfpl]: /LICENSE
[`renovate.json5`]: /renovate.json5
[`nix/modules/home/ai/`]: /nix/modules/home/ai/

<!-- Technology Links -->

[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nixos]: https://nixos.org
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[snowfall-lib]: https://snowfall.org
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
