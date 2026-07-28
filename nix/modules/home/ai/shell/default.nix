{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
  shellEnabled = config.modules.home.shell.enable;
in
{
  config = lib.mkIf (cfg.enable && shellEnabled) {
    programs.fish = {
      functions.ai = {
        description = "Context-aware Pi coding assistant";
        wraps = "pi";
        body = builtins.readFile ./ai.fish;
      };

      completions.ai = builtins.readFile ./ai-completions.fish;
    };
  };
}
