{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ghostty;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  ghosttyPackage = if isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
in
{
  options.modules.home.ghostty = {
    enable = mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      package = ghosttyPackage;
      settings = {
        font-family = "TX-02-Variable";
        font-variation = "wght=600";
        font-size = 16;
        font-feature = "+calt,+liga";
        theme = "github-dark-default";
      };
      themes = {
        github-dark-default = {
          palette = [
            "0=#484f58"
            "1=#ff7b72"
            "2=#3fb950"
            "3=#d29922"
            "4=#58a6ff"
            "5=#bc8cff"
            "6=#39c5cf"
            "7=#b1bac4"
            "8=#6e7681"
            "9=#ffa198"
            "10=#56d364"
            "11=#e3b341"
            "12=#79c0ff"
            "13=#d2a8ff"
            "14=#56d4dd"
            "15=#ffffff"
          ];
          background = "0d1117";
          foreground = "e6edf3";
          cursor-color = "2f81f7";
          cursor-text = "2f81f7";
          selection-background = "e6edf3";
          selection-foreground = "0d1117";
        };
      };
    };

    home.packages = [ ghosttyPackage ];
  };
}
