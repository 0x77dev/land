{ config, lib, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "GitHub_Dark";
    font = { name = "JetBrains Mono"; };
  };
}
