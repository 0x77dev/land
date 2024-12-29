{ pkgs, ... }: {
  packages = with pkgs; [
    git
    jq
    cachix
  ];

  dotenv.disableHint = true;
  languages.nix.enable = true;
  cachix.enable = true;
  cachix.pull = [ "land" "devenv" ];
  cachix.push = "land";

  pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks.nixpkgs-fmt.enable = true;
}
