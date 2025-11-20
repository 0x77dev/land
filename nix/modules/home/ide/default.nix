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
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cursorPackage = if isLinux then pkgs.code-cursor-fhs else pkgs.code-cursor;
in
{
  options.modules.home.ide = {
    enable = mkEnableOption "ide";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Code editor
      cursorPackage

      # LSP
      nixd
    ];

    # Configure Cursor (VSCode-based editor)
    programs.vscode = {
      enable = true;
      package = cursorPackage;

      # FHS wrapper on Linux for better extension support
      # Native macOS app on Darwin
    };

    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      extraPackages = [
        pkgs.opencode
        pkgs.nixd
        pkgs.${namespace}.tx-02-variable
        pkgs.nodePackages_latest.cspell
      ];

      # TODO: Uncomment this when home-manager release 25.11 is out
      # mutableUserSettings = true;
      # mutableUserKeymaps = true;
      # mutableUserTasks = true;
      # mutableUserDebug = true;

      extensions = [
        "nix"
        "vue"
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
            command = "opencode";
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
          dark = "Github Dark Colorblind";
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
                      command = "opencode";
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
