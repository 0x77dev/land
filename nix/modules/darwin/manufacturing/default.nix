{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.darwin.manufacturing;
in
{
  options.modules.darwin.manufacturing.enable =
    lib.mkEnableOption "Homebrew applications unavailable from nixpkgs on Darwin";

  config = lib.mkIf cfg.enable {
    homebrew.casks = [
      "bambu-studio"
      "freecad"
      "orcaslicer"
    ];
  };
}
