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
  config = lib.mkIf cfg.enable {
    # Create dedicated builder user on Darwin
    users.users.nixbuilder = {
      uid = 350; # High UID to avoid conflicts
      gid = 350;
      home = "/var/lib/nixbuilder";
      shell = pkgs.bash;
      description = "Nix remote build user";
    };

    users.groups.nixbuilder = {
      gid = 350;
    };

    # Trust the builder user
    nix.settings.trusted-users = [ "nixbuilder" ];

    # Configure sops secrets for both public and private keys
    sops.secrets."builders/ssh_public_key" = {
      mode = "0444";
      key = "ssh/public_key";
      sopsFile = inputs.self + "/nix/lib/builders/secrets.yaml";
    };

    sops.secrets."builders/ssh_private_key" = {
      mode = "0400";
      key = "ssh/private_key";
      sopsFile = inputs.self + "/nix/lib/builders/secrets.yaml";
    };

    # Darwin-specific: Manually configure authorized_keys
    # (openssh.authorizedKeys doesn't work the same way on Darwin)
    system.activationScripts.postActivation.text = lib.mkAfter ''
      # Create home and .ssh directory
      mkdir -p /var/lib/nixbuilder/.ssh
      chmod 700 /var/lib/nixbuilder/.ssh
      chown nixbuilder:nixbuilder /var/lib/nixbuilder

      # Copy public key to authorized_keys
      cat ${config.sops.secrets."builders/ssh_public_key".path} > /var/lib/nixbuilder/.ssh/authorized_keys
      chmod 600 /var/lib/nixbuilder/.ssh/authorized_keys
      chown nixbuilder:nixbuilder /var/lib/nixbuilder/.ssh /var/lib/nixbuilder/.ssh/authorized_keys
    '';

    # Ensure SSH is enabled
    services.openssh.enable = lib.mkDefault true;
  };
}
