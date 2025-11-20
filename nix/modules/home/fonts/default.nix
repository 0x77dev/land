{
  pkgs,
  namespace,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.fonts;
in
{
  options.modules.home.fonts = {
    enable = mkEnableOption "fonts";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs.${namespace}; [
      tx-02-variable
    ];

    # Required to autoload fonts from packages
    fonts.fontconfig.enable = true;
  };
}
