{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.reverse-engineering;
in
{
  options.modules.home.reverse-engineering = {
    enable = mkEnableOption "reverse-engineering";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      binwalk
      raider
      flashprog
      sasquatch
      dcfldd
      p7zip
      pigz
      pv
    ];
  };
}
