{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.manufacturing;
  packages = with pkgs; [
    bambu-studio
    freecad
    kicad
    openscad
    orca-slicer
  ];
in
{
  options.modules.home.manufacturing.enable = lib.mkEnableOption "CAD and 3D-printing tools";

  config = lib.mkIf cfg.enable {
    home.packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) packages;
  };
}
