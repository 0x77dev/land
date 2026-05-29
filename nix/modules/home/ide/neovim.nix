{
  inputs,
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
    (inputs.nixvim.homeModules.default or inputs.nixvim.homeManagerModules.default)
  ];

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      imports = [ ./nixvim.nix ];
      # We deliberately build nixvim against `unstable` (the flake `follows`);
      # set the source explicitly so nixvim doesn't warn about it.
      nixpkgs.source = inputs.unstable;
    };
  };
}
