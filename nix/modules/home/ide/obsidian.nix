{ config, lib, ... }:
with lib;
let
  cfg = config.modules.home.ide;
in
{
  config = mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
    };
  };
}
