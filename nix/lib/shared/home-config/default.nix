_:
{ lib, ... }:
{
  home = {
    stateVersion = lib.mkDefault "25.05";
    packages = lib.mkDefault [ ];
  };

  modules.home = {
    ai.enable = lib.mkDefault true;
    cloud.enable = lib.mkDefault true;
    fonts.enable = lib.mkDefault true;
    ghostty.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    ide.enable = lib.mkDefault true;
    media.enable = lib.mkDefault true;
    mobile.enable = lib.mkDefault true;
    network.enable = lib.mkDefault true;
    nix.enable = lib.mkDefault true;
    reverse-engineering.enable = lib.mkDefault true;
    secrets.enable = lib.mkDefault true;
    security.enable = lib.mkDefault true;
    shell.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    gpg.enable = lib.mkDefault true;
  };
}
