{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ffmpeg
    spotdl
    yt-dlp
    m8c
  ];
}
