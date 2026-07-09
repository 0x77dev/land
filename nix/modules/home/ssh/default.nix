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

  # Detect platform for socket paths
  # On Darwin: ~/.gnupg/S.gpg-agent*
  # On Linux: /run/user/$(id -u)/gnupg/S.gpg-agent*
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  # Local socket paths (where we're running SSH from)
  # Must use absolute paths because SSH doesn't expand ~ on the connect side
  localAgentExtraSocket =
    if isDarwin then
      "${config.home.homeDirectory}/.gnupg/S.gpg-agent.extra"
    else
      "/run/user/1000/gnupg/S.gpg-agent.extra";
  localAgentSshSocket =
    if isDarwin then
      "${config.home.homeDirectory}/.gnupg/S.gpg-agent.ssh"
    else
      "/run/user/1000/gnupg/S.gpg-agent.ssh";

  # Remote socket paths (Linux hosts)
  remoteAgentSocket = "/run/user/1000/gnupg/S.gpg-agent";
  remoteAgentSshSocket = "/run/user/1000/gnupg/S.gpg-agent.ssh";
in
{
  options.modules.home.ssh = {
    enable = mkEnableOption "ssh";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      unison
    ];

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
        # and ForwardAgent carries it onward for multi-hop (e.g. potato →
        # spark → vasyl).
        "spark.axolotl-sole.ts.net *.osv.computer" = {
          User = "mykhailo";
          ForwardAgent = true;
          IdentityAgent = localAgentSshSocket;
        };

        # Only forward to specific trusted servers
        "muscle muscle.0x77.computer muscle.osv.computer beefy beefy.0x77.computer" = {
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
