{
  config,
  lib,
  ...
}:
with lib;
let
  has = path: attrByPath path false config;
  hasGraphicalSession =
    has [
      "hardware"
      "graphics"
      "enable"
    ]
    && (
      has [
        "services"
        "displayManager"
        "gdm"
        "enable"
      ]
      || has [
        "services"
        "displayManager"
        "sddm"
        "enable"
      ]
      || has [
        "services"
        "xserver"
        "displayManager"
        "lightdm"
        "enable"
      ]
    );
in
{
  options.modules.graphical.enable = mkOption {
    type = types.bool;
    default = hasGraphicalSession;
    description = ''
      Whether this NixOS system has a graphical desktop session. Defaults to
      true only when hardware graphics and a display manager are enabled.
    '';
  };
}
