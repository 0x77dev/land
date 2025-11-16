{
  lib,
  pkgs,
  ...
}:
let
  userName = "0x77";
in
{
  system.stateVersion = 6;

  networking.hostName = lib.mkDefault "potato";

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/Users/${userName}";

      config = { };
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
}
