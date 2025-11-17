{
  lib,
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

  networking.hostName = lib.mkDefault "potato";

  environment.systemPackages = with pkgs.${namespace}; [
    ua-connect
  ];

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

  # Verified auto-updates
  services.verified-auto-update = {
    enable = true;
    flakeUrl = "github:0x77dev/land";
    allowedWorkflowRepository = "0x77dev/land";
  };
}
