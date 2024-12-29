{ inputs, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    autoMigrate = true;

    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "lyraphase/av-casks" = inputs.lyraphase-av-casks;
    };
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    global.autoUpdate = false;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    brews = [ "yubikey-personalization" "ykman" ];

    casks = [
      "arc"
      "aptakube"
      "spotify"
      "raycast"
      "notion-calendar"
      "google-chrome"
      "setapp"
      "telegram"
      "tailscale"
      "balenaetcher"
      "audio-hijack"
      "gpg-suite"
      "discord"
      "element"
      "1password"
      "1password-cli"
      "orbstack"
      "slack"
      "linear-linear"
      "zoom"
      "steam"
      "keka"
      "miniconda"
      "ultimaker-cura"
      "notion"
      "cursor"
      "zed"
      "tuple"
    ];

    masApps = {
      "Things" = 904280696;
      "WireGuard" = 1451685025;
      "Xcode" = 497799835;
      "Copilot" = 1447330651;
      "Parcel" = 639968404;
      "Home Assistant" = 1099568401;
      "Craft" = 1487937127;
    };
  };
}
