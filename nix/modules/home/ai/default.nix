{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ai;

  mcpServers = {
    context7 = {
      url = "https://mcp.context7.com/mcp";
    };
    gh_grep = {
      url = "https://mcp.grep.app";
    };
    nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
    };
    rust = {
      command = "rust-docs-mcp";
    };
    exa = {
      url = "https://mcp.exa.ai/mcp";
    };
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    theme = "system";
    disabled_providers = [ "opencode" ];

    provider = {
      ai-lab = {
        npm = "@ai-sdk/openai-compatible";
        name = "OSV AI Lab";
        # SEE: https://opencode.ai/docs/models/
        models = {
          "anthropic/claude-sonnet-4-5" = {
            id = "anthropic/claude-sonnet-4-5";
            name = "Claude Sonnet 4.5";
            release_date = "2025-09-29";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 3.15;
              output = 15.75;
              cache_read = 0.315;
              cache_write = 3.9375;
              context_over_200k = {
                input = 6.30;
                output = 23.625;
                cache_read = 0.63;
                cache_write = 7.875;
              };
            };
            limit = {
              context = 1000000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            headers = {
              "anthropic-beta" = "context-1m-2025-08-07";
            };
            # options = {
            #   reasoningEffort = "high";
            # };
          };
          "vertex_ai/gemini-3-pro" = {
            id = "vertex_ai/gemini-3-pro";
            name = "Gemini 3 Pro";
            release_date = "2025-11-18";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 2.10;
              output = 12.60;
              cache_read = 0.21;
              cache_write = 2.10;
              context_over_200k = {
                input = 4.20;
                output = 18.90;
                cache_read = 0.42;
                cache_write = 4.20;
              };
            };
            limit = {
              context = 1000000;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "video"
                "audio"
              ];
              output = [ "text" ];
            };
            options = {
              reasoningEffort = "high";
            };
          };
          "anthropic/claude-opus-4-1" = {
            id = "anthropic/claude-opus-4-1";
            name = "Claude Opus 4.1";
            release_date = "2025-08-05";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 15.75;
              output = 78.75;
              cache_read = 1.575;
              cache_write = 19.6875;
            };
            limit = {
              context = 200000;
              output = 32000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            options = {
              reasoningEffort = "high";
            };
          };
          "openai/gpt-5.1" = {
            id = "openai/gpt-5.1";
            name = "GPT 5.1";
            release_date = "2025-11-13";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 1.3125;
              output = 10.50;
              cache_read = 0.13125;
            };
            limit = {
              context = 196000;
              output = 128000;
            };
            modalities = {
              input = [
                "text"
                "image"
              ];
              output = [ "text" ];
            };
            options = {
              reasoningEffort = "high";
            };
          };
          "fireworks_ai/kimi-k2-thinking" = {
            id = "fireworks_ai/kimi-k2-thinking";
            name = "Kimi K2 Thinking";
            release_date = "2025-11-06";
            attachment = false;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 0.63;
              output = 2.625;
            };
            limit = {
              context = 256000;
              output = 16384;
            };
            modalities = {
              input = [ "text" ];
              output = [ "text" ];
            };
            options = {
              reasoningEffort = "high";
            };
          };
          "anthropic/claude-haiku-4-5" = {
            id = "anthropic/claude-haiku-4-5";
            name = "Claude Haiku 4.5";
            release_date = "2025-10-15";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 1.05;
              output = 5.25;
              cache_read = 0.105;
              cache_write = 1.3125;
            };
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
              ];
              output = [ "text" ];
            };
          };
          options = {
            reasoningEffort = "high";
          };
        };
        options = {
          apiKey = "{env:OSV_API_KEY}";
          baseURL = "https://developer.osv.engineering/inference/v1";
        };
      };
    }
    // lib.optionalAttrs config.modules.home.cloud.enable {
      vertex_ai = {
        npm = "@ai-sdk/google-vertex";
        name = "Vertex AI";
        options = {
          project = "{env:OC_GOOGLE_CLOUD_PROJECT}";
          location = "{env:OC_VERTEX_LOCATION}";
          googleApplicationCredentials = "${config.xdg.configHome}/gcloud/application_default_credentials.json";
        };
        models = {
          "gemini-3-pro-preview" = {
            id = "gemini-3-pro-preview";
            name = "Gemini 3 Pro Preview";
            release_date = "2025-11-18";
            attachment = true;
            reasoning = true;
            temperature = true;
            tool_call = true;
            cost = {
              input = 2.10;
              output = 12.60;
              cache_read = 0.21;
              cache_write = 2.10;
              context_over_200k = {
                input = 4.20;
                output = 18.90;
                cache_read = 0.42;
                cache_write = 4.20;
              };
            };
            limit = {
              context = 1000000;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "video"
                "audio"
              ];
              output = [ "text" ];
            };
            options = {
              thinkingConfig = {
                includeThoughts = true;
                thinkingBudget = 32768;
              };
            };
          };
        };
      };
    };

    model =
      if config.modules.home.cloud.enable then
        "vertex_ai/gemini-3-pro-preview"
      else
        "ai-lab/anthropic/claude-sonnet-4-5";

    mcp = {
      context7 = {
        type = "remote";
        inherit (mcpServers.context7) url;
        enabled = true;
      };
      gh_grep = {
        type = "remote";
        inherit (mcpServers.gh_grep) url;
        enabled = true;
      };
      nixos = {
        type = "local";
        command = [ mcpServers.nixos.command ];
        enabled = true;
      };
      rust = {
        type = "local";
        command = [ mcpServers.rust.command ];
        enabled = true;
      };
      exa = {
        type = "remote";
        inherit (mcpServers.exa) url;
        enabled = true;
      };
    };
  };
in
{
  options.modules.home.ai = {
    enable = mkEnableOption "ai";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      aichat
      opencode
      mcp-nixos
    ];

    programs.mcp = {
      enable = true;
      servers = mcpServers;
    };

    # TODO: Migrate to `programs.opencode` on next home-manager release
    home.file."${config.xdg.configHome}/opencode/config.json".text = builtins.toJSON opencodeConfig;
  };
}
