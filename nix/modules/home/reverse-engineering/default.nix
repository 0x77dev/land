{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.reverse-engineering;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  options.modules.home.reverse-engineering = {
    enable = mkEnableOption "reverse-engineering";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        binwalk
        flashprog
        sasquatch
        dcfldd
        p7zip
        pigz
        pv
      ]
      ++ optionals (!isDarwin) [ raider ];
  };
}
