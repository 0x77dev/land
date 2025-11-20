{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ssh;
in
{
  options.modules.home.ssh = {
    enable = mkEnableOption "ssh";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
    };
  };
}
