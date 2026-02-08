{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.openclaw;
in
{
  options.modules.home.openclaw = {
    enable = mkEnableOption "openclaw";
  };

  config = mkIf cfg.enable {
    programs.openclaw = {
      enable = true;

      # Avoid collisions with packages from the shell module
      excludeTools = [
        "nodejs_22"
        "git"
        "curl"
        "jq"
        "ripgrep"
        "ffmpeg"
        "python3"
      ];

      config = {
        gateway = {
          mode = "local";
          bind = "loopback";
          tailscale.mode = "serve";
        };

        env.shellEnv = {
          enabled = true;
          timeoutMs = 15000;
        };
      };

      # Don't expose plugin packages on PATH (avoids osc-progress collision)
      exposePluginPackages = false;

      # Linux-compatible bundled plugins
      # (peekaboo, bird, poltergeist, imsg are Darwin-only)
      bundledPlugins = {
        summarize.enable = true;
        oracle.enable = true;
        sag.enable = true;
        camsnap.enable = true;
        gogcli.enable = true;
        goplaces.enable = true;
      };
    };
  };
}
