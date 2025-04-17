# formats/proxmox-lxc/default.nix
#
# Custom format for Proxmox LXC containers
# Based on the tarball format but optimized for Proxmox LXC

{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  imports = [
    # Import the virtualization module for Proxmox
    "${toString modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  # Use tarball as the base format
  formatAttr = "tarball";

  # Customize extension for Proxmox LXC
  fileExtension = ".tar.xz";

  # Add any additional configuration specific to Proxmox LXC
  # Disable bootloader as it's not needed in LXC
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  # Configure console access
  systemd.services."getty@tty1".enable = true;
  systemd.services."getty@ttyS0".enable = true;
  systemd.services."serial-getty@ttyS0".enable = true;

  # Container-specific optimizations
  systemd.enableEmergencyMode = false;

  # Ensure SSH is enabled for remote access
  services.openssh.enable = lib.mkDefault true;
}
