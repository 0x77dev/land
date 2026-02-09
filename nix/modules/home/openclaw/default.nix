{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.openclaw;
  homeDir = config.home.homeDirectory;
  configPath = "${homeDir}/.openclaw/openclaw.json";

  # Sops secrets to pass to the gateway as env vars
  secretEnvVars = {
    FURNACE_GLM_API_KEY = config.sops.secrets.FURNACE_GLM_API_KEY.path;
    FURNACE_GLM_ENDPOINT = config.sops.secrets.FURNACE_GLM_ENDPOINT.path;
    OPENCLAW_GATEWAY_TOKEN = config.sops.secrets.OPENCLAW_GATEWAY_TOKEN.path;
    TELEGRAM_BOT_TOKEN = config.sops.secrets.TELEGRAM_BOT_TOKEN.path;
    FURNACE_EMBEDDINGS_ENDPOINT = config.sops.secrets.FURNACE_EMBEDDINGS_ENDPOINT.path;
  };

  loadSecretsScript = pkgs.writeShellScript "openclaw-load-secrets" ''
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: path: ''export ${name}="$(${lib.getExe' pkgs.coreutils "cat"} "${path}")"''
      ) secretEnvVars
    )}

    # Resolve env vars in the Nix-managed config to a writable copy
    cfg="${configPath}"
    if [ -L "$cfg" ] || [ ! -w "$cfg" ]; then
      resolved="$(${lib.getExe' pkgs.coreutils "cat"} "$cfg")"
      for var in ${lib.concatStringsSep " " (lib.attrNames secretEnvVars)}; do
        resolved="$(echo "$resolved" | ${lib.getExe' pkgs.gnused "sed"} "s|\''${$var}|$(printenv "$var")|g")"
      done
      rm -f "$cfg"
      echo "$resolved" > "$cfg"
      chmod 600 "$cfg"
    fi

    exec "$@"
  '';
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
          auth.token = "\${OPENCLAW_GATEWAY_TOKEN}";
        };

        # Override runtime mutation from openclaw doctor
        plugins.entries.telegram.enabled = true;

        channels.telegram = {
          enabled = true;
          botToken = "\${TELEGRAM_BOT_TOKEN}";
          dmPolicy = "pairing";
          groups."*".requireMention = true;
        };

        agents.defaults = {
          model.primary = "kimi-osv/moonshotai/kimi-k2p5";
          models."kimi-osv/moonshotai/kimi-k2p5" = { };
          memorySearch = {
            enabled = true;
            provider = "openai";
            model = "Qwen/Qwen3-Embedding-0.6B";
            remote = {
              baseUrl = "\${FURNACE_EMBEDDINGS_ENDPOINT}";
              apiKey = "\${FURNACE_GLM_API_KEY}";
              headers = {
                "User-Agent" = "openclaw/1.0 land0x77";
                "Authorization" = "Bearer \${FURNACE_GLM_API_KEY}";
              };
              batch.enabled = true;
            };
          };
        };

        models = {
          mode = "merge";
          providers."kimi-osv" = {
            baseUrl = "\${FURNACE_GLM_ENDPOINT}";
            apiKey = "\${FURNACE_GLM_API_KEY}";
            api = "openai-completions";
            headers = {
              "User-Agent" = "openclaw/1.0 land0x77";
              "Authorization" = "Bearer \${FURNACE_GLM_API_KEY}";
            };
            models = [
              {
                id = "moonshotai/kimi-k2p5";
                name = "Kimi K2.5";
                reasoning = true;
                input = [
                  "text"
                  "image"
                ];
                cost = {
                  input = 0;
                  output = 0;
                  cacheRead = 0;
                  cacheWrite = 0;
                };
                contextWindow = 262144;
                maxTokens = 131072;
              }
            ];
          };
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

    # Wrap the gateway ExecStart to load sops secrets and resolve config
    systemd.user.services.openclaw-gateway = {
      Unit.After = [ "sops-nix.service" ];
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = mkForce "${loadSecretsScript} ${config.programs.openclaw.package}/bin/openclaw gateway --port 18789";
        Environment = mkAfter [
          "PATH=${homeDir}/.local/bin:${homeDir}/go/bin:${homeDir}/.bun/bin:/run/current-system/sw/bin:\${PATH}"
        ];
      };
    };
  };
}
