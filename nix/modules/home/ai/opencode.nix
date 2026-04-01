{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";

  rawSettings = builtins.fromJSON (builtins.readFile (configDir + "/opencode.json"));
  settings = removeAttrs rawSettings [ "$schema" ];
in
{
  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      inherit settings;
    };

    xdg.configFile."opencode/oh-my-opencode.json".source = configDir + "/oh-my-opencode.json";
  };
}
