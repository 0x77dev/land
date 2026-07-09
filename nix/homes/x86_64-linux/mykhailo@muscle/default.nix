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
  home = shared.home // {
    # Consistent cursor everywhere, including Xwayland and Qt apps that read
    # XCURSOR_* instead of dconf.
    pointerCursor = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  modules.home = shared.modules.home // {
    ai.enable = true;
    browser.enable = true;
    cloud.enable = true;
    fonts.enable = true;
    ghostty.enable = true;
    git.enable = true;
    ide.enable = true;
    media.enable = true;
    network.enable = true;
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
  };

  # Appearance, kept declarative. Cursor/icon themes are pinned because the
  # prior KDE install left `breeze` in dconf, which renders broken in GNOME.
  dconf.settings =
    let
      wallpaper = {
        color-shading-type = "solid";
        picture-options = "zoom";
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-l.jxl";
        primary-color = "#86b6ef";
        secondary-color = "#000000";
      };
    in
    {
      "org/gnome/desktop/interface" = {
        cursor-theme = "Adwaita";
        icon-theme = "Adwaita";
        color-scheme = "prefer-dark";
        accent-color = "blue";
        monospace-font-name = "Hack 10";
      };

      "org/gnome/desktop/background" = wallpaper // {
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/curvy-d.jxl";
      };

      "org/gnome/desktop/screensaver" = wallpaper;
    };
}
