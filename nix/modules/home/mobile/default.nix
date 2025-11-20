{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.mobile;
in
{
  options.modules.home.mobile = {
    enable = mkEnableOption "mobile";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      android-tools
    ];
  };
}
