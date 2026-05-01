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
    onActivation.autoUpdate = lib.mkDefault true;
    onActivation.upgrade = lib.mkDefault true;

    brews = lib.mkDefault [
      "cmux"
      "steipete/tap/gogcli"
      "superhuman"
    ];
  };
}
