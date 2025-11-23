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

# Build Incus VM image and metadata
incus-vm-build name:
  nix build .#nixosConfigurations.{{name}}.config.system.build.qemuImage -o result-{{name}}-qemu
  nix build .#nixosConfigurations.{{name}}.config.system.build.metadata -o result-{{name}}-metadata

# Import Incus VM image
incus-vm-import name alias:
  incus image import --alias {{alias}} \
    result-{{name}}-metadata/tarball/nixos-system-x86_64-linux.tar.xz \
    result-{{name}}-qemu/nixos.qcow2

# Build and import Incus VM in one command
incus-vm-deploy name alias:
  @just incus-vm-build {{name}}
  @just incus-vm-import {{name}} {{alias}}

# Launch Incus VM instance
incus-vm-launch alias instance:
  incus launch --vm {{alias}} {{instance}} -c security.secureboot=false
