_:
{ lib, ... }:
{
  home = {
    stateVersion = lib.mkDefault "25.05";
    packages = lib.mkDefault [ ];
    sessionVariables = {
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "cursor --wait";
    };
  };

  programs.neovim = {
    enable = lib.mkDefault true;
    defaultEditor = lib.mkDefault false;
  };

  modules.home = {
    ai.enable = lib.mkDefault false;
    cloud.enable = lib.mkDefault false;
    fonts.enable = lib.mkDefault false;
    ghostty.enable = lib.mkDefault false;
    git.enable = lib.mkDefault true;
    ide.enable = lib.mkDefault false;
    media.enable = lib.mkDefault false;
    mobile.enable = lib.mkDefault false;
    network.enable = lib.mkDefault false;
    nix.enable = lib.mkDefault false;
    p2p.enable = lib.mkDefault false;
    reverse-engineering.enable = lib.mkDefault false;
    comms.enable = lib.mkDefault false;
    secrets.backend = lib.mkDefault "disabled";
    security-tools.enable = lib.mkDefault true;
    shell.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    gpg.enable = lib.mkDefault true;
  };
}
