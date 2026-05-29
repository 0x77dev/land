{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.modules.installer;
in
{
  options.modules.installer.enable = lib.mkEnableOption "minimal NixOS installer image (SSH + keys + kexec)";

  config = lib.mkIf cfg.enable {
    networking.hostName = lib.mkDefault "installer";

    # ZFS kernel support (without enabling ZFS) so installs onto ZFS pools work.
    modules.filesystem.zfs.kernelSupport = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    users.users.nixos = {
      isNormalUser = true;
      description = "NixOS Installer User";
      extraGroups = [ "wheel" ];
      initialPassword = "wakeupneo";
      openssh.authorizedKeys.keys =
        (lib.${namespace}.shared.user-config { inherit lib; }).openssh.authorizedKeys.keys;
    };

    security.sudo.wheelNeedsPassword = false;

    # kexec tooling for nixos-anywhere installs.
    environment.systemPackages = [ pkgs.kexec-tools ];
  };
}
