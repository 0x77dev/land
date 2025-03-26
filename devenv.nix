{ pkgs, ... }: {
  packages = with pkgs; [
    git
    git-crypt
    jq
    cachix
    age
    sops
    nixos-anywhere
    nixos-rebuild
    ssh-to-age
  ];

  dotenv.disableHint = true;
  cachix.enable = true;
  cachix.pull = [ "land" "devenv" ];
  cachix.push = "land";

  languages.nix.enable = true;
  languages.opentofu.enable = true;

  pre-commit.hooks.actionlint.enable = true;
  pre-commit.hooks.shellcheck.enable = true;
  pre-commit.hooks.nixpkgs-fmt.enable = true;
  pre-commit.hooks.mdsh.enable = true;
  pre-commit.hooks.flake-checker.enable = true;
  pre-commit.hooks.terraform-format.enable = true;
  pre-commit.hooks.pre-commit-hook-ensure-sops.enable = true;
}
