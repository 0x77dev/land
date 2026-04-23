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
    user = lib.mkDefault primaryUser;
    autoMigrate = lib.mkDefault true;

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };

    mutableTaps = lib.mkDefault true;
  };

  homebrew = {
    enable = lib.mkDefault true;
    taps = lib.mkDefault (builtins.attrNames config.nix-homebrew.taps ++ [ "steipete/tap" ]);

    global.autoUpdate = lib.mkDefault false;
    # Keep interactive brew usage quiet, but refresh and upgrade during nix-darwin activation.
    onActivation.autoUpdate = lib.mkDefault true;
    onActivation.upgrade = lib.mkDefault true;

    brews = lib.mkDefault [
      "steipete/tap/gogcli"
    ];

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
      "google-chrome"
      "helium-browser"
      "slack"
      "linear-linear"
      "zoom"
      "steam"
      "superhuman"
      "notion"
      "homebrew/cask/betterdisplay"
    ];
  };
}
