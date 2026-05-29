{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.modules.installer;
  keys = (lib.${namespace}.shared.user-config { inherit lib; }).openssh.authorizedKeys.keys;
in
{
  options.modules.installer.enable = lib.mkEnableOption "NixOS installer image extras (SSH keys + kexec)";

  # Layers on top of nixpkgs' `installer/cd-dvd/installation-cd-base.nix`, which
  # already provides the `nixos` live user, sshd, and passwordless sudo. We only
  # add key-based SSH access and the tooling for `nixos-anywhere`.
  config = lib.mkIf cfg.enable {
    # ZFS kernel support (without enabling ZFS) so installs onto ZFS pools work.
    modules.filesystem.zfs.kernelSupport = true;

    # `nixos-anywhere` runs its install phase as root over SSH, so root must
    # accept our key. Both users get the keys; password auth stays off.
    users.users.root.openssh.authorizedKeys.keys = keys;
    users.users.nixos.openssh.authorizedKeys.keys = keys;

    services.openssh.settings = {
      PermitRootLogin = lib.mkForce "prohibit-password";
      PasswordAuthentication = lib.mkForce false;
    };

    environment.systemPackages = [ pkgs.kexec-tools ];
  };
}
