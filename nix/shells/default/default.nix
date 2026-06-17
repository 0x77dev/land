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
      # Match the Home Manager module: give nixvim non-elaborated platform
      # strings so its unstable lib does not reject stable platform records.
      nixpkgs = {
        source = inputs.unstable;
        buildPlatform = system;
        hostPlatform = system;
      };
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
