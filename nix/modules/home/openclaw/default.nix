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

    telegramAllowFrom = mkOption {
      type = types.listOf types.int;
      default = [ ];
      description = "Telegram user IDs allowed to interact with the bot.";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      OPENCLAW_TELEGRAM_TOKEN.sopsFile = ./secrets.yaml;
      OPENCLAW_GATEWAY_TOKEN.sopsFile = ./secrets.yaml;
      ANTHROPIC_API_KEY.sopsFile = ./secrets.yaml;
    };

    programs.openclaw = {
      enable = true;

      config = {
        gateway.mode = "local";

        channels.telegram = {
          tokenFile = config.sops.secrets.OPENCLAW_TELEGRAM_TOKEN.path;
          allowFrom = cfg.telegramAllowFrom;
        };
      };

      # OPENCLAW_GATEWAY_TOKEN and ANTHROPIC_API_KEY are exported
      # as env vars by the shell init (sops paths loaded automatically).

      bundledPlugins = {
        summarize.enable = true;
        oracle.enable = true;
      };
    };

    # Export OpenClaw secrets as env vars in all shells
    programs = {
      fish.interactiveShellInit = mkAfter ''
        test -f "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}"; and set -gx OPENCLAW_GATEWAY_TOKEN (cat "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}")
        test -f "${config.sops.secrets.ANTHROPIC_API_KEY.path}"; and set -gx ANTHROPIC_API_KEY (cat "${config.sops.secrets.ANTHROPIC_API_KEY.path}")
      '';
      bash.initExtra = mkAfter ''
        [ -f "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}" ] && export OPENCLAW_GATEWAY_TOKEN="$(cat "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}")"
        [ -f "${config.sops.secrets.ANTHROPIC_API_KEY.path}" ] && export ANTHROPIC_API_KEY="$(cat "${config.sops.secrets.ANTHROPIC_API_KEY.path}")"
      '';
      zsh.initContent = mkAfter ''
        [ -f "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}" ] && export OPENCLAW_GATEWAY_TOKEN="$(cat "${config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path}")"
        [ -f "${config.sops.secrets.ANTHROPIC_API_KEY.path}" ] && export ANTHROPIC_API_KEY="$(cat "${config.sops.secrets.ANTHROPIC_API_KEY.path}")"
      '';
    };
  };
}
