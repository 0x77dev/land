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
    rust = {
      command = "~/.local/bin/rust-docs-mcp";
    };
    exa = {
      url = "https://mcp.exa.ai/mcp";
    };
    linear = {
      url = "https://mcp.linear.app/mcp";
    };
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    theme = "system";
    disabled_providers = [ "opencode" ];

    # NOTE: Extended thinking is NOT supported through OpenAI-compatible proxies
    # (LiteLLM doesn't preserve thinking blocks in conversation history).
    # Use native Anthropic SDK if you need thinking.
    provider = {
      ai-lab = {
        npm = "@ai-sdk/openai-compatible";
        name = "OSV AI Lab";
        options = {
          apiKey = "{env:OSV_API_KEY}";
          baseURL = "https://developer.osv.engineering/inference/v1";
        };
        models = {
          "anthropic/claude-sonnet-4-5" = {
            name = "Claude Sonnet 4.5";
            limit = {
              context = 1000000;
              output = 64000;
            };
          };
          "anthropic/claude-opus-4-5" = {
            name = "Claude Opus 4.5";
            limit = {
              context = 200000;
              output = 32000;
            };
          };
          "anthropic/claude-opus-4-1" = {
            name = "Claude Opus 4.1";
            limit = {
              context = 200000;
              output = 32000;
            };
          };
          "anthropic/claude-haiku-4-5" = {
            name = "Claude Haiku 4.5";
            limit = {
              context = 200000;
              output = 64000;
            };
          };
          "vertex_ai/gemini-3-pro" = {
            name = "Gemini 3 Pro";
            limit = {
              context = 1000000;
              output = 65536;
            };
          };
          "openai/gpt-5.1" = {
            name = "GPT 5.1";
            limit = {
              context = 196000;
              output = 128000;
            };
          };
          "fireworks_ai/kimi-k2-thinking" = {
            name = "Kimi K2 Thinking";
            limit = {
              context = 256000;
              output = 16384;
            };
          };
        };
      };
      "furnace-exp-glm47" = {
        npm = "@ai-sdk/openai-compatible";
        name = "GLM-4.7 on Furnace Cluster";
        options = {
          apiKey = "{env:FURNACE_GLM_API_KEY}";
          baseURL = "{env:FURNACE_GLM_ENDPOINT}";
        };
        models = {
          "zai-org/GLM-4.7" = {
            name = "GLM-4.7";
            limit = {
              context = 200000;
              output = 131072;
            };
          };
        };
      };
    };

    model = "furnace-exp-glm47/zai-org/GLM-4.7";

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
    services.ollama.enable = true;

    home.packages = with pkgs; [
      aichat
      ollama
      opencode
    ];

    programs.mcp = {
      enable = true;
      servers = mcpServers;
    };

    programs.opencode = {
      enable = true;
      settings = opencodeConfig;
    };
  };
}
