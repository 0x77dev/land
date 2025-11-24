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
        discordo # Discord
        iamb # Matrix
      ]
      ++
        lib.optionals
          (
            pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64
            || pkgs.stdenv.isDarwin && (pkgs.stdenv.isx86_64 || pkgs.stdenv.isAarch64)
          )
          [
            slack
          ];

    programs.aerc.enable = true;
  };
}
