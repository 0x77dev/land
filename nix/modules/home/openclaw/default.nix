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
    programs.openclaw = {
      enable = true;

      config = {
        gateway = {
          mode = "local";
          bind = "loopback";
          tailscale.mode = "serve";
        };
      };

      bundledPlugins = {
        summarize.enable = true;
        oracle.enable = true;
      };
    };
  };
}
