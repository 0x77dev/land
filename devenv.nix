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
    just
  ];

  dotenv.disableHint = true;
  cachix.enable = true;
  cachix.pull = [ "land" "devenv" ];
  cachix.push = "land";

  languages.nix.enable = true;
  languages.opentofu.enable = true;
  languages.ansible.enable = true;

  git-hooks.hooks.actionlint.enable = true;
  git-hooks.hooks.shellcheck.enable = true;
  git-hooks.hooks.nixpkgs-fmt.enable = true;
  git-hooks.hooks.mdsh.enable = true;
  git-hooks.hooks.flake-checker.enable = true;
  git-hooks.hooks.terraform-format.enable = true;
  git-hooks.hooks.pre-commit-hook-ensure-sops.enable = true;
}
