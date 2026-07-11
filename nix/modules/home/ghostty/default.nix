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
  fonts = config.modules.home.fonts.presentation;
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
      installVimSyntax = true;
      themes = {
        gdd = {
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
        gld = {
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
        font-family = [
          fonts.families.monospace
          fonts.families.monospaceFallback
          fonts.families.symbolsMonospace
          fonts.families.emoji
        ];
        font-variation = "wght=${toString fonts.adapters.ghostty.weight}";
        font-variation-bold = "wght=${toString fonts.adapters.ghostty.boldWeight}";
        font-size = fonts.adapters.ghostty.size;
        font-feature = "+calt,+liga";
        keybind = lib.optionals isDarwin [
          "super+d=new_split:down"
          "super+shift+d=new_split:right"
        ];
        theme = "dark:gdd,light:gld";
      };
    };

    # Keep the terminal usable when this module is enabled without the shared
    # font module; otherwise that module is the sole font-package owner.
    home.packages = optional (!config.modules.home.fonts.enable) pkgs.${namespace}.tx-02-variable;

    fonts.fontconfig.enable = true;
  };
}
