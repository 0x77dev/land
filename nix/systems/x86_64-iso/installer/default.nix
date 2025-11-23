{
  lib,
  namespace,
  pkgs,
  ...
}:
{
  # Minimal installer configuration
  networking.hostName = "installer";

  # ZFS kernel support (without enabling ZFS)
  modules.filesystem.zfs.kernelSupport = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Create nixos user with password-less sudo and SSH keys
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Installer User";
    extraGroups = [ "wheel" ];
    initialPassword = "wakeupneo";
    openssh.authorizedKeys.keys =
      (lib.${namespace}.shared.user-config { inherit lib; }).openssh.authorizedKeys.keys;
  };

  # Password-less sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Include kexec tools for nixos-anywhere
  environment.systemPackages = with pkgs; [
    kexec-tools
  ];

  system.stateVersion = "25.05";
}
