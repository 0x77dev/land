{
  pkgs,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    aichat
    ollama
    opencode
    mcp-nixos
  ];

  services.ollama.enable = true;

  # TODO: Migrate to `programs.opencode` on next home-manager release
  home.file."${config.xdg.configHome}/opencode/config.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    theme = "system";

    provider = {
      ai-lab = {
        npm = "@ai-sdk/openai-compatible";
        name = "OSV AI Lab";
        models = {
          "anthropic/claude-sonnet-4-5" = {
            id = "anthropic/claude-sonnet-4-5";
            name = "Claude Sonnet 4.5";
          };
          "anthropic/claude-haiku-4-5" = {
            id = "anthropic/claude-haiku-4-5";
            name = "Claude Haiku 4.5";
          };
          "anthropic/claude-opus-4-1" = {
            id = "anthropic/claude-opus-4-1";
            name = "Claude Opus 4.1";
          };
          "fireworks_ai/kimi-k2-thinking" = {
            id = "fireworks_ai/kimi-k2-thinking";
            name = "Kimi K2 Thinking";
          };
        };
        options = {
          apiKey = "{env:OSV_API_KEY}";
          baseURL = "{env:OSV_INFERENCE_ENDPOINT}";
          headers = {
            "anthropic-beta" = "context-1m-2025-08-07";
          };
        };
      };
      ollama = {
        name = "Ollama";
        models = {
          "gpt-oss:20b" = { };
        };
      };
    };

    model = "ai-lab/anthropic/claude-sonnet-4-5";

    mcp = {
      context7 = {
        type = "remote";
        url = "https://mcp.context7.com/mcp";
        enabled = true;
      };
      gh_grep = {
        type = "remote";
        url = "https://mcp.grep.app";
        enabled = true;
      };
      nixos = {
        type = "local";
        command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
        enabled = true;
      };
      exa = {
        type = "remote";
        url = "https://mcp.exa.ai/mcp";
        enabled = true;
      };
    };
  };
}
