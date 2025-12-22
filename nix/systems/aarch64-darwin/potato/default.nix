{
  pkgs,
  ...
}:
let
  userName = "0x77";
in
{
  system.stateVersion = 6;
  system.primaryUser = userName;

  networking = {
    hostName = "potato";
    domain = "0x77.computer";
  };

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/Users/${userName}";

      config = {
        modules.home = {
          secrets.backend = "gpg";
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

  services = {
    openssh.enable = true;
    ipfs = {
      enable = true;
      enableGarbageCollection = true;
    };
  };
}
