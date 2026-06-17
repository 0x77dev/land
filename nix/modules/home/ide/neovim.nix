{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
in
{
  imports = [
    (inputs.nixvim.homeModules.default or inputs.nixvim.homeManagerModules.default)
  ];

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      imports = [ ./nixvim.nix ];
      # We deliberately build nixvim against `unstable` (the flake `follows`);
      # set the source explicitly so nixvim doesn't warn about it. Pass platform
      # strings, not stable nixpkgs' elaborated platform records: unstable's
      # lib.systems.elaborate rejects pre-26.11 records containing linux-kernel.
      nixpkgs = {
        source = inputs.unstable;
        buildPlatform = pkgs.stdenv.buildPlatform.system;
        hostPlatform = pkgs.stdenv.hostPlatform.system;
      };
    };
  };
}
