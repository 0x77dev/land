# land 🏠

![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/0x77dev/land/build.yaml)
[![Cachix Cache](https://img.shields.io/badge/cachix-land-blue.svg)](https://app.cachix.org/cache/land)
![Maintenance](https://img.shields.io/maintenance/yes/2024) 

My homelab and dotfiles managed with Nix. This repository contains declarative configurations for my machines.

## Overview

This repository uses [Nix](https://nixos.org/) to manage:
- macOS machines (via nix-darwin)
- NixOS systems
- Home Manager configurations

## Usage

1. Install Nix following the [official instructions](https://nixos.org/download.html)
2. Apply configuration:
   - For macOS: `nix run nix-darwin --experimental-features 'nix-command flakes' -- switch --flake github:0x77dev/land`
   - For NixOS: `nix run nixos-rebuild --experimental-features 'nix-command flakes' -- switch --flake github:0x77dev/land`
   - For home-manager: `nix run home-manager --experimental-features 'nix-command flakes' -- switch --flake github:0x77dev/land`

## Structure

- `modules/` - Shared configuration modules
- `modules/home/` - Home Manager configuration modules
- `systems/` - Machine-specific configurations
- `flake.nix` - Flake
- `.envrc` - Direnv configuration

## Forking

If you want to use this repository as a starting point for your own homelab, you can do so by forking it and customizing it to your needs.

You can start by adding your own machines to the `flake.nix` file, and then customize the `modules/` and `systems/` directories to your liking.
