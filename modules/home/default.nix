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
    ./neovim.nix
    ./chromium.nix
  ];

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "24.11";
}
