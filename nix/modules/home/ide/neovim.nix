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
    programs.nixvim.enable = true;
  };
}
