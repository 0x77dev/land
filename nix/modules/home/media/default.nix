{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.media;
in
{
  options.modules.home.media = {
    enable = mkEnableOption "media";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
      spotdl
      yt-dlp
      m8c
    ];
  };
}
