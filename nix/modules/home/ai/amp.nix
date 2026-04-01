{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.ai;
  configDir = lib.snowfall.fs.get-file "config";
  baseSettings = builtins.fromJSON (builtins.readFile (configDir + "/amp/settings.json"));
  settings = baseSettings // {
    "amp.mcpServers" = config.programs.mcp.servers;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.amp-cli ];

    xdg.configFile."amp/settings.json".text = builtins.toJSON settings;
  };
}
