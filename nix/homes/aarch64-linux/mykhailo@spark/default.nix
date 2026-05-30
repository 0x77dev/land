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
      pinentryPackage = pkgs.pinentry-qt;
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
  };
}
