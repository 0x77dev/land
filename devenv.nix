{ pkgs, ... }: {
  packages = with pkgs; [
    git
    git-crypt
    jq
    cachix
    age
    sops
    nixos-anywhere
  ];

  dotenv.disableHint = true;
  languages.nix.enable = true;
  cachix.enable = true;
  cachix.pull = [ "land" "devenv" ];
  cachix.push = "land";

  pre-commit.hooks.actionlint.enable = true;
  pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks.nixpkgs-fmt.enable = true;
  pre-commit.hooks.mdsh.enable = true;
  pre-commit.hooks.flake-checker.enable = true;
  pre-commit.hooks.pre-commit-hook-ensure-sops.enable = true;
}
