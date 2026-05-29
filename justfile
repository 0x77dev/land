default: help

help:
  @just --list

# Build the generic (x86_64) installer ISO
iso:
  nom build .#nixosConfigurations.installer.config.system.build.isoImage -o result-installer

# Build the NVIDIA DGX Spark (aarch64, GB10) installer ISO
spark-iso:
  nom build .#nixosConfigurations.spark-installer.config.system.build.isoImage -o result-spark-installer

# Install NixOS on a host at an IP address
# Use `just iso` or any linux distro with kexec-tools installed
provision host username_at_hostname:
  nixos-anywhere --flake .#{{host}} {{username_at_hostname}}

# Rebuild NixOS host
nixos-rebuild host username_at_hostname:
  nixos-rebuild switch --flake .#{{host}} --use-remote-sudo --build-host {{username_at_hostname}} --target-host {{username_at_hostname}}
