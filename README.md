# land 🏠

[![Cachix Cache](https://img.shields.io/badge/cachix-land-blue.svg)](https://app.cachix.org/cache/land)
![Maintenance](https://img.shields.io/maintenance/yes/2025)

My homelab and dotfiles managed with Nix. This repository contains declarative configurations for my machines.

## Overview

This repository uses [Nix](https://nixos.org/) to manage:

- macOS machines (via nix-darwin)
- NixOS systems
- Home Manager configurations
- WSL 2 instances

## Usage

1. Install Nix following the [official instructions](https://nixos.org/download.html)
2. Apply configuration:

   - For macOS:
     ```shell
     nix run nix-darwin --experimental-features 'nix-command flakes' -- switch --refresh --flake github:0x77dev/land#<hostname>
     ```
   - For NixOS:
     ```shell
     nixos-rebuild switch --refresh --flake github:0x77dev/land#<hostname>
     ```
   - For home-manager (if not defined in NixOS or nix-darwin):
     ```shell
     nix run home-manager --experimental-features 'nix-command flakes' -- switch --refresh --experimental-features 'nix-command flakes' --flake github:0x77dev/land#<username>@<hostname> -b backup
     ```
   - For WSL:

     ```shell
     # Build the tarball
     sudo nix run --experimental-features 'nix-command flakes' github:0x77dev/land#nixosConfigurations.wsl.config.system.build.tarballBuilder
     ```

     ```powershell
     # Import the tarball
     New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\WSL-Land"
     wsl.exe --import Land "$env:USERPROFILE\WSL-Land" nixos-wsl.tar.gz --version 2
     ```

     ```powershell
     # Set the default user
     wsl.exe -d Land -u mykhailo
     # Run the WSL instance
     wsl.exe -d Land
     # Optional: Set NixOS as the default WSL distribution
     wsl.exe -s Land
     ```

## Structure

- `modules/` - Shared configuration modules
- `modules/home/` - Home Manager configuration modules
- `systems/` - Machine-specific configurations
- `flake.nix` - Flake
- `.envrc` - Direnv configuration

## Forking

If you want to use this repository as a starting point for your own homelab, you can do so by forking it and customizing it to your needs.

You can start by adding your own machines to the `flake.nix` file, and then customize the `modules/` and `systems/` directories to your liking.
