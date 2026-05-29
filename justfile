default: help

help:
  @just --list

# Build the installer ISO for an architecture (x86_64 or aarch64)
iso arch="x86_64":
  nom build .#isoConfigurations.installer-{{arch}} -o result-installer-{{arch}}

# Install NixOS on a host at an IP address
# Use `just iso` or any linux distro with kexec-tools installed
provision host username_at_hostname:
  nixos-anywhere --flake .#{{host}} {{username_at_hostname}}

# Rebuild NixOS host
nixos-rebuild host username_at_hostname:
  nixos-rebuild switch --flake .#{{host}} --use-remote-sudo --build-host {{username_at_hostname}} --target-host {{username_at_hostname}}
