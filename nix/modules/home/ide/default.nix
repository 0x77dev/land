{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
in
{
  imports = [
    ./vscode.nix
    ./zed.nix
    ./neovim.nix
  ];

  options.modules.home.ide = {
    enable = mkEnableOption "ide";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
    ];
  };
}
