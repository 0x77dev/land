{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.comms;
in
{
  options.modules.home.comms = {
    enable = mkEnableOption "comms";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        irssi # IRC
        tg # Telegram
        iamb # Matrix
      ]
      # discord/slack have no aarch64-linux builds; gate them to x86_64-linux and Darwin.
      ++
        lib.optionals
          (
            pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64
            || pkgs.stdenv.isDarwin && (pkgs.stdenv.isx86_64 || pkgs.stdenv.isAarch64)
          )
          [
            discord
            slack
          ];

    programs.aerc.enable = true;
  };
}
