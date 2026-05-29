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
      gitFull
      git-crypt
      jq
      gitsign
      nixos-rebuild
      inputs.nixos-anywhere.packages.${system}.nixos-anywhere
      just
      cachix
      rpiboot
      zstd
      pv
    ]
    ++ preCommit.enabledPackages;
}
