{ ... }:

{
  imports = [
    ./fonts.nix
    ./git.nix
    ./gpg.nix
    ./ssh.nix
    ./shell.nix
    ./kitty.nix
    ./vscode.nix
    ./chromium.nix
    ./neovim.nix
  ];

  programs.home-manager.enable = true;

  home.stateVersion = "25.05";
}
