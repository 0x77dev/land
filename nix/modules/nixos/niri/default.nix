{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.niri;
in
{
  options.modules.niri = {
    enable = mkEnableOption "Niri scrollable-tiling Wayland compositor";
  };

  config = mkIf cfg.enable {
    # Enable niri via niri-flake's NixOS module
    # This automatically sets up: polkit, keyring, portals, dconf, opengl, fonts, swaylock pam
    programs.niri.enable = true;

    # XWayland support via xwayland-satellite
    environment.systemPackages = with pkgs; [
      xwayland-satellite
    ];

    # Display manager - GDM supports niri sessions
    services.xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };

    # Environment variables for Wayland/Electron apps
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
