{
  pkgs,
  ...
}:
let
  userName = "mykhailo";
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

  modules.darwin.dock.enable = true;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    _1password-gui
    _1password-cli
  ];

  services = {
    openssh.enable = true;
    ipfs = {
      enable = true;
      enableGarbageCollection = true;
    };
  };
}
