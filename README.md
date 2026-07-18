# land

Declarative NixOS and nix-darwin infrastructure using Nix flakes, Home Manager,
and Snowfall Lib.

## Highlights

- Helium packaging with store-backed Widevine integration on Linux.
- YubiKey-backed FIDO2 authentication for workstation login and privilege elevation.

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
