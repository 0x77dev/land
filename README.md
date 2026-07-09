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

Build an installer ISO. The generic image covers x86_64; the DGX Spark needs a
dedicated aarch64 image (GB10 requires the `arm64.nobti` kernel arg to boot):

```bash
just iso        # generic x86_64 installer
just spark-iso  # NVIDIA DGX Spark (GB10) installer
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

### Secrets

Nothing secret lives in Nix and there is no secret-management machinery.
Services on `spark` and `vasyl` read host-local files that the configuration
seeds empty with safe permissions. External credentials are filled once by
hand over SSH (the owning unit sits failed/retrying until then); internal
self-secrets are generated write-once on the box and need no manual entry.
This runbook is deliberately kept out of the agent-facing docs shipped to
`vasyl`.

On `vasyl` (the agent VM):

- `/var/lib/hermes/secret.env` (0600 hermes) — merged into `$HERMES_HOME/.env`
  on every activation; never edit `.env` itself, it is rewritten wholesale.
  Apply an edit with
  `sudo /run/current-system/activate && sudo systemctl restart hermes-agent`
  (a reboot does the same). Keys in this file gate features:
  - **Matrix** (the enabled channel): `MATRIX_HOMESERVER`,
    `MATRIX_ACCESS_TOKEN`, `MATRIX_USER_ID`. The gateway turns a platform on
    purely from its credentials — there is no config.yaml switch. Optional
    behavior (`matrix.require_mention`, `matrix.allowed_rooms`, ...) is a
    hand-edit to the group-writable `$HERMES_HOME/config.yaml`; keys Nix does
    not declare survive rebuilds via the deep-merge.
  - **HTTP API server**: `API_SERVER_KEY` is auto-generated into this file
    (write-once, never regenerated) by the `hermes-secret-init` oneshot before
    the agent starts — nothing to fill manually.
  - **Hermes dashboard**: `HERMES_DASHBOARD_BASIC_AUTH_USERNAME`,
    `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`, and
    `HERMES_DASHBOARD_BASIC_AUTH_SECRET` are auto-generated into this file
    (write-once, never regenerated) by `hermes-secret-init`. The dashboard unit
    reads this file directly; without auth config it fails closed rather than
    serving an unauthenticated control plane.
  - **Deferred, keyed the same way**: image generation (`FAL_KEY`), X search
    (`XAI_API_KEY`), cloud browser, cloud TTS/STT, extra search/extract
    backends, hosted memory providers, and the other messaging platforms.
    (`computer_use` is macOS-only and cannot run in the VM regardless.)
- Tailscale (no secret file) — vasyl is its own tailnet node; authenticate
  once with `sudo tailscale up --ssh` (interactive browser login; needs
  vasyl's NAT'd internet through `spark`). Node state persists on the
  volume — no re-auth across reboots.

On `spark` (host), for the Parakeet NIM STT container — both take the same
free NGC API key from [ngc.nvidia.com](https://ngc.nvidia.com):

- `/var/lib/nim/ngc-key` (0600 root) — the raw key; used with the literal
  `$oauthtoken` username to log in to `nvcr.io` and pull the image.
- `/var/lib/nim/ngc.env` (0600 root) — `NGC_API_KEY=<same key>`, the
  container's model-download credential. After filling both:
  `sudo systemctl restart docker-parakeet-nim`.

## Systems

| Host     | Platform         | Role              | Specs                     |
| -------- | ---------------- | ----------------- | ------------------------- |
| `potato` | `aarch64-darwin` | Workstation       | M4 Max, 48GB              |
| `tomato` | `x86_64-linux`   | Homelab / Cluster | MS-01, i9-13900H, 96GB    |
| `spark`  | `aarch64-linux`  | AI/Compute        | NVIDIA DGX Spark (GB10)   |
| `timey`  | `aarch64-linux`  | IoT/Edge/Time     | RPi 5, eMMC               |
| `beefy`  | `aarch64-darwin` | Media             | M2 Ultra, 64GB            |
| `muscle` | `x86_64-linux`   | AI/Compute        | TR 7985WX, 2x RTX6000 Ada |
| `ghost`  | `x86_64-linux`   | Fun               | T480, 16GB                |
| `vasyl`  | `aarch64-linux`  | AI Agent          | microVM on `spark`        |

`vasyl` is a [microvm.nix][microvm-nix] guest built and deployed together with
`spark`: rebuilding the host updates and restarts the VM. It runs
[Hermes Agent][hermes-agent] against the host's Ollama over a private tap
network, with a local SearXNG instance backing web search and the host GPU
serving voice (Parakeet NIM STT in a container, Kokoro TTS as a pure-Nix CUDA
service); credentials are filled manually in host-local files — see
[Secrets](#secrets) and
[`nix/systems/aarch64-linux/vasyl/`](/nix/systems/aarch64-linux/vasyl/).

`muscle` also exposes CUDA Ollama on the LAN/Tailscale interface, using the same
agent model set as `spark`. The shared pull set includes Qwen3-Coder-Next as the
long-context coding/agent pick and stays bounded by Muscle's 2x RTX 6000 Ada VRAM
budget.

## Development

```bash
nix develop
nix flake check
nix flake update
```

Managed hosts expose this flake's inputs through both the system flake
registry and `NIX_PATH`, so pinned input references work directly
(`nix shell unstable#grype`) and legacy channels resolve to the locked
revisions (`nix-build '<nixpkgs>' -A hello`).

Darwin hosts offload `x86_64-linux` and `aarch64-linux` builds to
`muscle` via system-level Nix distributed builds. Use `nix build -j0`
when you want to force a Linux-target build onto the remote builder.

## Automation

GitHub Actions validates the flake on both Linux and Darwin, building
every declared system and home closure and pushing successful builds to
`land.cachix.org`. Dependencies are updated manually with
`nix flake update`.

AI-enabled Home Manager profiles configure the terminal agent stack managed in
[`nix/modules/home/ai/`]. OpenCode is the agent runtime, with global skills and
Cursor/Neovim integrations managed declaratively. OpenCode settings live in the
Home Manager module at
[`nix/modules/home/ai/opencode.nix`](/nix/modules/home/ai/opencode.nix).

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
[`nix/modules/home/ai/`]: /nix/modules/home/ai/

<!-- Technology Links -->

[nix-flakes]: https://nixos.wiki/wiki/Flakes
[nixos]: https://nixos.org
[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[snowfall-lib]: https://snowfall.org
[nixos-anywhere]: https://github.com/nix-community/nixos-anywhere
[microvm-nix]: https://github.com/microvm-nix/microvm.nix
[hermes-agent]: https://github.com/NousResearch/hermes-agent
