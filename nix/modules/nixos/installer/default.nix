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
  options.modules.installer.enable = lib.mkEnableOption "NixOS installer image extras (SSH keys + kexec)";

  # Layers on top of nixpkgs' `installer/cd-dvd/installation-cd-base.nix`, which
  # already provides the `nixos` live user, sshd, and passwordless sudo. We only
  # add key-based SSH access and the tooling for `nixos-anywhere`.
  config = lib.mkIf cfg.enable {
    # ZFS kernel support (without enabling ZFS) so installs onto ZFS pools work.
    modules.filesystem.zfs.kernelSupport = true;

    users.users.nixos.openssh.authorizedKeys.keys =
      (lib.${namespace}.shared.user-config { inherit lib; }).openssh.authorizedKeys.keys;

    # Key-only SSH: the live `nixos` user has an empty password, so password
    # auth over the network must stay off.
    services.openssh.settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = lib.mkForce false;
    };

    environment.systemPackages = [ pkgs.kexec-tools ];
  };
}
