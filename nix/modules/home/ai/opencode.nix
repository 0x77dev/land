{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";

  rawSettings = builtins.fromJSON (builtins.readFile (configDir + "/opencode.json"));
in
{
  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      settings = removeAttrs rawSettings [ "$schema" ];
      context = configDir + "/ai/AGENTS.md";
    };
  };
}
