{ inputs, ... }: {
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
      "assemblyai/assemblyai" = inputs.homebrew-assemblyai;
    };
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    global.autoUpdate = false;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;

    casks = [
      "arc"
      "homerow"
      "aptakube"
      "spotify"
      "raycast"
      "notion-calendar"
      "google-chrome"
      "setapp"
      "telegram"
      "homebrew/cask/tailscale"
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
      "notion"
      "cursor"
    ];

    masApps = {
      "Things" = 904280696;
      "WireGuard" = 1451685025;
      "Xcode" = 497799835;
      "Parcel" = 639968404;
    };
  };
}
