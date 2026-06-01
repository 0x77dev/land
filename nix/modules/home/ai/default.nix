{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ai;
in
{
  imports = [
    ./opencode.nix
    ./shell
  ];

  options.modules.home.ai = {
    enable = lib.mkEnableOption "ai";
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      OTEL_SDK_DISABLED = "true";
    };
  };
}
