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
        pkgs.${namespace}.tx-02-variable
        pkgs.nodePackages_latest.cspell
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

        theme = {
          mode = "system";
          dark = "Github Dark";
          light = "Github Light";
        };

        buffer_font_family = "TX-02-Variable";
        buffer_font_features = {
          calt = true;
          liga = true;
        };

        languages = {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
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
