{
  lib,
  config,
  inputs,
  ...
}:
let
  userNames = builtins.attrNames config.snowfallorg.users;
  primaryUser = builtins.head userNames;
in
{
  nix-homebrew = {
    enable = lib.mkDefault true;
    enableRosetta = lib.mkDefault true;
    user = lib.mkDefault primaryUser;
    autoMigrate = lib.mkDefault false;

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };

    mutableTaps = lib.mkDefault false;
  };

  homebrew = {
    enable = lib.mkDefault true;
    taps = lib.mkDefault (builtins.attrNames config.nix-homebrew.taps);

    global.autoUpdate = lib.mkDefault false;
    onActivation.autoUpdate = lib.mkDefault false;
    onActivation.upgrade = lib.mkDefault false;

    casks = lib.mkDefault [
      "arc"
      "homerow"
      "aptakube"
      "spotify"
      "raycast"
      "notion-calendar"
      "helium-browser"
      "setapp"
      "telegram"
      "homebrew/cask/tailscale-app"
      "balenaetcher"
      "audio-hijack"
      "gpg-suite"
      "discord"
      "orbstack"
      "slack"
      "linear-linear"
      "zoom"
      "steam"
      "notion"
    ];

    masApps = lib.mkDefault {
      "Things" = 904280696;
      "WireGuard" = 1451685025;
      # TODO: Xcode automatic install fails
      # "Xcode" = 497799835;
    };
  };
}
