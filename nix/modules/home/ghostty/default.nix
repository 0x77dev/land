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
      settings = {
        font-family = "TX-02-Variable";
        font-variation = "wght=600";
        font-size = 16;
        font-feature = "+calt,+liga";
        theme = "dark:GitHub Dark Default,light:GitHub Light Default";
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
