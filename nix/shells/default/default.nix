{
  lib,
  inputs,
  namespace,
  system,
  mkShell,
  pkgs,
  ...
}:
let
  preCommit = lib.${namespace}.git-hooks.mkRun {
    inherit system pkgs;
    src = inputs.self;
  };
in
mkShell {
  name = "${namespace}-default-shell";
  inherit (preCommit) shellHook;
  packages =
    with pkgs;
    [
      git
      sops
      age
      ssh-to-age
      gitsign
      nixos-rebuild
      inputs.deploy-rs.packages.${system}.deploy-rs
      inputs.nixos-anywhere.packages.${system}.nixos-anywhere
    ]
    ++ preCommit.enabledPackages;
}
