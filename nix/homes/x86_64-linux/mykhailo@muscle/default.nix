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

  # GNOME reads cursor/icon themes from dconf; the prior KDE install left
  # `breeze` set there, which is gone now and renders broken. Pin Adwaita.
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = "Adwaita";
    icon-theme = "Adwaita";
    color-scheme = "prefer-dark";
  };
}
