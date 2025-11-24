{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.builders;
in
{
  # This module extends the existing builders module
  # It configures the server-side when modules.builders.enable = true

  config = lib.mkIf cfg.enable {
    # Create dedicated builder user
    users.users.nixbuilder = {
      isSystemUser = true;
      group = "nixbuilder";
      description = "Nix remote build user";
      shell = pkgs.bash;
    };

    users.groups.nixbuilder = { };

    # Trust the builder user for Nix operations
    nix.settings.trusted-users = [ "nixbuilder" ];

    # Configure authorized_keys via systemd tmpfile
    # This reads the secret at runtime, not evaluation time
    systemd.tmpfiles.rules = [
      "d /home/nixbuilder 0700 nixbuilder nixbuilder -"
      "d /home/nixbuilder/.ssh 0700 nixbuilder nixbuilder -"
      "L+ /home/nixbuilder/.ssh/authorized_keys 0600 nixbuilder nixbuilder - ${
        config.sops.secrets."builders/ssh_public_key".path
      }"
    ];

    # Configure sops secrets for both public and private keys
    sops.secrets."builders/ssh_public_key" = {
      mode = "0444"; # World-readable (it's a public key)
      key = "ssh/public_key";
      sopsFile = inputs.self + "/nix/lib/builders/secrets.yaml";
    };

    sops.secrets."builders/ssh_private_key" = {
      mode = "0400"; # Read-only for root
      key = "ssh/private_key";
      sopsFile = inputs.self + "/nix/lib/builders/secrets.yaml";
    };

    # Ensure SSH is enabled
    services.openssh.enable = lib.mkDefault true;
  };
}
