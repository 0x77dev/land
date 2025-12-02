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
  programs.home-manager.enable = true;

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
    nix.enable = true;
    p2p.enable = true;
    reverse-engineering.enable = true;
    comms.enable = true;
    security.enable = true;
    shell.enable = true;
    ssh.enable = true;
    gpg = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
  };

  # Disable GNOME Keyring SSH component (conflicts with GPG agent SSH)
  xdg.configFile."autostart/gnome-keyring-ssh.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=SSH Key Agent
    Hidden=true
  '';

  programs.zed-editor.userSettings.buffer_font_size = 18;
}
