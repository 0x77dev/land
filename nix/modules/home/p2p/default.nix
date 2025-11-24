{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.p2p;
in
{
  options.modules.home.p2p = {
    enable = mkEnableOption "p2p";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kubo
      iroh
      dumbpipe
    ];
  };
}
