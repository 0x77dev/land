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

  # Same nixvim configuration that home-manager builds, as a standalone `nvim`.
  # nixvim follows `unstable`, so let it use its own matching nixpkgs rather than
  # the shell's stable `pkgs` (mismatched releases break the nixvim build).
  nvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
    module = {
      imports = [ ../../modules/home/ide/nixvim.nix ];
      nixpkgs.source = inputs.unstable;
    };
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
      nvim
    ]
    ++ preCommit.enabledPackages;
}
