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
    # Configure users and groups
    users = {
      # Add nixbuilder to known users/groups for nix-darwin management (append to existing lists)
      knownUsers = [ "nixbuilder" ];
      knownGroups = [ "nixbuilder" ];

      # Create dedicated builder user on Darwin
      users.nixbuilder = {
        uid = 450; # High UID to avoid conflicts (350 is taken by nixbld)
        gid = 450;
        home = "/var/lib/nixbuilder";
        shell = pkgs.bash;
        description = "Nix remote build user";
      };

      groups.nixbuilder = {
        gid = 450;
      };
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
      # Wait for user creation (users are created in the 'users' activation script)
      if ! id -u nixbuilder >/dev/null 2>&1; then
        echo "Warning: nixbuilder user not yet created, skipping SSH setup"
        exit 0
      fi

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
