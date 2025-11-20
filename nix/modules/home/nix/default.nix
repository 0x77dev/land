{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.nix;
in
{
  options.modules.home.nix = {
    enable = mkEnableOption "nix";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nix-output-monitor
      cachix
    ];
  };
}
