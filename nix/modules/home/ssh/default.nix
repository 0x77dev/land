{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.ssh;
  # Check if GPG module is enabled for conditional configuration
  gpgEnabled = config.modules.home.gpg.enable or false;

  machines = lib.land.shared.machines;
  gpgRemoteForwardHosts = concatStringsSep " " (
    concatMap (m: m.aliases ++ [ m.hostname ]) (attrValues (filterAttrs (_: m: m.forwardGpg) machines))
  );

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  inherit
    (lib.land.shared.gpg-agent {
      inherit isDarwin;
      homeDirectory = config.home.homeDirectory;
    })
    localAgentExtraSocket
    localAgentSshSocket
    remoteAgentSocket
    remoteAgentSshSocket
    ;
in
{
  options.modules.home.ssh = {
    enable = mkEnableOption "ssh";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      # GPG agent forwarding configuration
      extraConfig = mkIf gpgEnabled ''
        # Allow SSH to unbind existing sockets before binding new ones
        StreamLocalBindUnlink yes
      '';

      settings = {
        # Default settings for all hosts (replaces enableDefaultConfig)
        "*" = {
          AddKeysToAgent = "yes";
        };
      }
      // optionalAttrs gpgEnabled {
        # Lab hosts reached with the YubiKey-backed identity (gpg-agent's ssh
        # socket): IdentityAgent offers it without touching the default agent,
        # and ForwardAgent carries it onward for multi-hop (e.g. potato ->
        # spark -> vasyl).
        "spark.axolotl-sole.ts.net *.osv.computer" = {
          User = "mykhailo";
          ForwardAgent = true;
          IdentityAgent = localAgentSshSocket;
        };

        # Only forward to specific trusted servers
        "${gpgRemoteForwardHosts}" = {
          ForwardAgent = true;
          # Forward the GPG agent's extra socket to the remote system
          # Local: agent-extra-socket -> Remote: agent-socket (replaces remote agent)
          # Local: agent-ssh-socket -> Remote: agent-ssh-socket (for SSH keys)
          # GPG agent forwarding (for GPG operations: sign, decrypt, etc.)
          RemoteForward = [
            "${remoteAgentSocket} ${localAgentExtraSocket}"
            "${remoteAgentSshSocket} ${localAgentSshSocket}"
          ];
        };
      };
    };
  };
}
