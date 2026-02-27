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
        description = "AI coding assistant (opencode)";
        wraps = "opencode";
        body = builtins.readFile ./ai.fish;
      };

      completions.ai = builtins.readFile ./ai-completions.fish;
    };
  };
}
