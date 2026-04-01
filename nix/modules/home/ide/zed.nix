{
  pkgs,
  namespace,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
in
{
  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      extraPackages = [
        pkgs.opencode
        pkgs.nixd
        pkgs.oxlint
        pkgs.oxfmt
        pkgs.${namespace}.tx-02-variable
        pkgs.cspell
      ];

      mutableUserSettings = true;
      mutableUserKeymaps = true;
      mutableUserTasks = true;
      mutableUserDebug = true;

      extensions = [
        "nix"
        "vue"
        "sql"
        "lua"
        "opentofu"
        "dockerfile"
        "colorizer"
        "editorconfig"
        "oxc"
        "opencode"
        "github-theme"
        "cspell"
        "git-firefly"
      ];

      userSettings = {
        agent_servers = {
          OpenCode = {
            command = "${pkgs.opencode}/bin/opencode";
            args = [ "acp" ];
          };
        };

        terminal = {
          env = {
            EDITOR = "zed --wait";
          };
        };

        "theme" = {
          "dark" = "GitHub Dark";
          "light" = "Github Light";
          "mode" = "system";
        };

        buffer_font_family = "TX-02-Variable";
        buffer_font_features = {
          calt = true;
          liga = true;
        };

        languages = {
          JavaScript = {
            format_on_save = "on";
            prettier.allowed = false;
            formatter = [
              {
                language_server.name = "oxfmt";
              }
              {
                code_action = "source.fixAll.oxc";
              }
            ];
          };
          TypeScript = {
            format_on_save = "on";
            prettier.allowed = false;
            formatter = [
              {
                language_server.name = "oxfmt";
              }
              {
                code_action = "source.fixAll.oxc";
              }
            ];
          };
          TSX = {
            format_on_save = "on";
            prettier.allowed = false;
            formatter = [
              {
                language_server.name = "oxfmt";
              }
              {
                code_action = "source.fixAll.oxc";
              }
            ];
          };
          JSON = {
            format_on_save = "on";
            prettier.allowed = false;
            formatter = [
              {
                language_server.name = "oxfmt";
              }
            ];
          };
          Nix = {
            language_servers = [ "nixd" ];
          };
        };

        lsp = {
          oxlint = {
            binary = {
              path = "${pkgs.oxlint}/bin/oxlint";
            };
            initialization_options = {
              settings = {
                configPath = null;
                run = "onType";
                disableNestedConfig = false;
                fixKind = "safe_fix";
                unusedDisableDirectives = "deny";
              };
            };
          };

          oxfmt = {
            binary = {
              path = "${pkgs.oxfmt}/bin/oxfmt";
            };
            initialization_options = {
              settings = {
                "fmt.configPath" = null;
                run = "onSave";
              };
            };
          };
        };
      };

      userKeymaps = [
        {
          bindings = {
            "cmd-alt-o" = [
              "agent::NewExternalAgentThread"
              {
                agent = {
                  custom = {
                    name = "OpenCode";
                    command = {
                      command = "${pkgs.opencode}/bin/opencode";
                      args = [ "acp" ];
                    };
                  };
                };
              }
            ];
          };
        }
      ];
    };
  };
}
