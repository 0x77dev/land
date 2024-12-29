{ inputs, pkgs, ... }:

let
  user = if pkgs.stdenv.isDarwin then "0x77" else "mykhailo";
in
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  environment.systemPackages = with pkgs; [
    home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "nixhomemgrbak";

    users.${user} = {
      imports = [
        ./fonts.nix
        ./git.nix
        ./gpg.nix
        ./ssh.nix
        ./shell.nix
        ./kitty.nix
        ./vscode.nix
      ];

      programs.home-manager.enable = true;

      home.stateVersion = "24.11";
    };
  };
}
