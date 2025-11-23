default: help

help:
  @just --list

# Build the installer ISO
iso:
  nom build .#isoConfigurations.installer -o result-installer

# Install NixOS on a host at an IP address
# Use `just iso` or any linux distro with kexec-tools installed
provision host username_at_hostname:
  nixos-anywhere --flake .#{{host}} {{username_at_hostname}}

# Deploy host
deploy host:
  deploy -s --remote-build .#{{host}}

# Rebuild NixOS host
nixos-rebuild host username_at_hostname:
  nixos-rebuild switch --flake .#{{host}} --use-remote-sudo --build-host {{username_at_hostname}} --target-host {{username_at_hostname}}
