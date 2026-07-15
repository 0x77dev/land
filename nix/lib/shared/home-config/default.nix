_:
{ lib, ... }:
{
  home = {
    stateVersion = lib.mkDefault "25.05";
    packages = lib.mkDefault [ ];
    sessionVariables = {
      # `edit` (shell module) dispatches per invocation: nvim over SSH or in
      # headless contexts, Cursor in a local GUI session.
      EDITOR = lib.mkDefault "edit";
      VISUAL = lib.mkDefault "edit";
    };
  };

  programs.neovim = {
    enable = lib.mkDefault true;
    defaultEditor = lib.mkDefault false;
  };

  modules.home = {
    ai.enable = lib.mkDefault false;
    browser.enable = lib.mkDefault false;
    cloud.enable = lib.mkDefault false;
    fonts.enable = lib.mkDefault false;
    ghostty.enable = lib.mkDefault false;
    gnome.enable = lib.mkDefault false;
    git.enable = lib.mkDefault true;
    ide.enable = lib.mkDefault false;
    manufacturing.enable = lib.mkDefault false;
    media.enable = lib.mkDefault false;
    mobile.enable = lib.mkDefault false;
    network.enable = lib.mkDefault false;
    nix.enable = lib.mkDefault false;
    p2p.enable = lib.mkDefault false;
    reverse-engineering.enable = lib.mkDefault false;
    comms.enable = lib.mkDefault false;
    security-tools.enable = lib.mkDefault true;
    shell.enable = lib.mkDefault true;
    ssh.enable = lib.mkDefault true;
    gpg.enable = lib.mkDefault true;
  };
}
