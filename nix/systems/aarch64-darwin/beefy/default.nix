{
  pkgs,
  namespace,
  ...
}:
let
  userName = "0x77";
in
{
  system.stateVersion = 6;
  system.primaryUser = userName;

  modules.builders.enable = true;

  networking = {
    hostName = "beefy";
    domain = "0x77.computer";
  };

  environment.systemPackages = with pkgs.${namespace}; [
    ua-connect
  ];

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/Users/${userName}";

      config = {
        modules.home = {
          ai.enable = true;
          cloud.enable = true;
          fonts.enable = true;
          ghostty.enable = true;
          git.enable = true;
          ide.enable = true;
          media.enable = true;
          mobile.enable = true;
          network.enable = true;
          nix.enable = true;
          p2p.enable = true;
          reverse-engineering.enable = true;
          comms.enable = true;
          security-tools.enable = true;
          shell.enable = true;
          ssh.enable = true;
          gpg.enable = true;
        };
      };
    };
  };

  # Additional user configuration for nix-darwin
  users = {
    users.${userName} = {
      name = userName;
      uid = 501;
      home = "/Users/${userName}";
      shell = pkgs.fish;
    };

    knownUsers = [ userName ];
  };

  programs.fish.enable = true;

  services.openssh = {
    enable = true;
    # TODO: extraConfig is not in 25.05 yet
    # extraConfig = {
    #   PermitRootLogin = "no";
    #   # NOTE: don't do PasswordAuthentication = false; it will prevent remote FileVault unlock
    #   AllowAgentForwarding = true;
    #   StreamLocalBindUnlink = true;
    # };
  };
}
