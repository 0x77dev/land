# Proxmox LXC support for NixOS
# Based on https://nixos.wiki/wiki/Proxmox_Linux_Container

{ config
, lib
, pkgs
, ...
}:

with lib;

{
  options.proxmox.lxc = {
    enable = mkEnableOption "Proxmox LXC container configuration";

    unprivilegedContainer = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this is an unprivileged Proxmox container.
        Most Proxmox LXC containers run in unprivileged mode.
      '';
    };

    networkInterface = mkOption {
      type = types.str;
      default = "eth0";
      description = "The network interface used by the Proxmox container.";
    };

    bootLoader = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable bootloader configurations.
        Should be disabled for Proxmox LXC containers.
      '';
    };

    enableSerialConsole = mkOption {
      type = types.bool;
      default = true;
      description = "Enable serial console for Proxmox access.";
    };

    tmpfsSize = mkOption {
      type = types.str;
      default = "8G";
      description = "Size of the tmpfs filesystem.";
    };
  };

  config = mkIf config.proxmox.lxc.enable {
    # Essential Proxmox LXC container configurations

    # Boot configurations - typically disabled for containers
    boot.loader.grub.enable = config.proxmox.lxc.bootLoader;
    boot.loader.systemd-boot.enable = config.proxmox.lxc.bootLoader;

    # Ensure system.stateVersion is set in your system configuration

    # Set console configuration for proper Proxmox console access
    systemd.services."getty@tty1".enable = config.proxmox.lxc.enableSerialConsole;
    systemd.services."getty@ttyS0".enable = config.proxmox.lxc.enableSerialConsole;
    systemd.services."serial-getty@ttyS0".enable = config.proxmox.lxc.enableSerialConsole;

    # Basic networking configuration
    networking = {
      useDHCP = mkDefault false;
      interfaces.${config.proxmox.lxc.networkInterface}.useDHCP = mkDefault true;
    };

    # tmpfs configuration for optimal performance
    fileSystems."/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=${config.proxmox.lxc.tmpfsSize}"
        "mode=1777"
      ];
    };

    # Security adjustments for Proxmox containers
    security = mkIf config.proxmox.lxc.unprivilegedContainer {
      # Adjust AppArmor/SELinux as necessary for your environment
      apparmor.enable = mkDefault false;
    };

    # For unprivileged containers, adjust kernel parameters
    boot.kernel.sysctl = mkIf config.proxmox.lxc.unprivilegedContainer {
      "kernel.unprivileged_userns_clone" = mkDefault 1;
    };

    # Container optimization
    systemd.enableEmergencyMode = false;

    # Additional packages useful for Proxmox containers
    environment.systemPackages = with pkgs; [
      wget
      curl
      vim
      btop
      tmux
      iotop
    ];

    # Enable nix flakes by default for easier management
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nix.settings.trusted-users = [ "root" "@wheel" ];
  };
}
