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
    home.packages = with pkgs; [
      irssi # IRC
      tg # Telegram
      discordo # Discord
      iamb # Matrix
    ];

    programs.aerc.enable = true;
  };
}
