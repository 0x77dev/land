# land

Declarative NixOS and nix-darwin infrastructure using Nix flakes, Home Manager,
and Snowfall Lib.

## Highlights

- One Snowfall-managed fleet spanning x86-64 and ARM NixOS, Apple Silicon
  nix-darwin, Home Manager, installer images, and a NixOS microVM.
- Secure Boot with signed UKIs, declarative full-disk encryption, and
  YubiKey-backed FIDO2 authentication for login and privilege elevation.
- Staged Cachix Deploy rollouts with host and Home Manager closures updated as
  one unit, plus CI checks derived automatically from discovered flake outputs.
- NVIDIA compute across dual RTX 6000 Ada GPUs and the DGX Spark GB10, including
  CUDA, containers, GPUDirect Storage, and shared Ollama model policy.
- A dedicated Hermes Agent microVM with controlled secrets, model routing,
  dashboard access, and host-integrated lifecycle management.
- Daily-updated coding agents from Numtide's `llm-agents.nix`, while Hermes
  remains sourced from its official package and NixOS module.
- HDR and VRR gaming through GNOME Wayland, NVIDIA, Gamescope, GameMode,
  MangoHud, Steam, and GE-Proton, alongside OpenXR, ALVR, and Monado tooling.
- Helium packaging with store-backed Widevine, 1Password and Vicinae native
  messaging, managed browser extensions, and its built-in uBlock Origin.
- GPS/PPS and PTP timekeeping with chrony integration, exporters, and shared
  observability dashboards.
- Reproducible development environments with pinned flake inputs, native and
  cross-architecture builders, treefmt, and repository-wide pre-commit checks.

## Quick start

```sh
nix develop
just --list
just provision "<host>" "<user>@<hostname>"
just nixos-rebuild "<host>" "<user>@<hostname>"
```

## Development

```sh
nix fmt
nix flake check
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for repository structure and conventions.

## License

[WTFPL](LICENSE)
