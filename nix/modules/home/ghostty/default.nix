{
  pkgs,
  config,
  lib,
  namespace,
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
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
      themes = {
        github-dark = {
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
        github-light = {
          palette = [
            "0=#24292f"
            "1=#cf222e"
            "2=#116329"
            "3=#4d2d00"
            "4=#0969da"
            "5=#8250df"
            "6=#1b7c83"
            "7=#6e7781"
            "8=#57606a"
            "9=#a40e26"
            "10=#1a7f37"
            "11=#633c01"
            "12=#218bff"
            "13=#a475f9"
            "14=#3192aa"
            "15=#8c959f"
          ];
          background = "ffffff";
          foreground = "1f2328";
          cursor-color = "0969da";
          cursor-text = "0969da";
          selection-background = "1f2328";
          selection-foreground = "ffffff";
        };
      };
      settings = {
        font-family = "TX-02-Variable";
        font-variation = "wght=600";
        font-size = 16;
        font-feature = "+calt,+liga";
        theme = "dark:github-dark,light:github-light";
      };
    };

    # Ensure TX-02 font is available
    home.packages = [
      ghosttyPackage
      pkgs.${namespace}.tx-02-variable
    ];

    # Enable fontconfig to register fonts
    fonts.fontconfig.enable = true;
  };
}
