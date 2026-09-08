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

    mutableTaps = lib.mkDefault false;
  };

  homebrew = {
    enable = lib.mkDefault true;
    taps = lib.mkDefault (builtins.attrNames config.nix-homebrew.taps);

    global.autoUpdate = lib.mkDefault false;
    onActivation.autoUpdate = lib.mkDefault false;
    onActivation.upgrade = lib.mkDefault true;

    casks = lib.mkDefault [
      "superhuman"
      "soundsource"
      "audio-hijack"
      "loopback"
      "fission"
      "ua-connect"
      "betterdisplay"
    ];
  };
}
