{
  lib,
  pkgs,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  inherit (shared) home;

  modules.home = shared.modules.home // {
    secrets.backend = "age";
    ai.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    network.enable = true;
    niri.enable = true;
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security-tools.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  programs = {
    home-manager.enable = true;
    zed-editor.userSettings.buffer_font_size = 18;

    # Samsung Odyssey G95SC ultra-wide monitor configuration
    niri.settings.outputs."DP-4" = {
      mode = {
        width = 5120;
        height = 1440;
        refresh = 239.999;
      };
      scale = 1.0;
      position = {
        x = 0;
        y = 0;
      };
      variable-refresh-rate = true;
    };
  };
}
