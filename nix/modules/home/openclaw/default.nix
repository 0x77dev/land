{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.openclaw;
in
{
  options.modules.home.openclaw = {
    enable = mkEnableOption "openclaw";
  };

  config = mkIf cfg.enable {
    programs.openclaw.enable = true;
  };
}
