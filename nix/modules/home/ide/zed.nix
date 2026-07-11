{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.ide;
  fonts = config.modules.home.fonts.presentation;

  # Zed sizes fonts in logical pixels; 12 pt maps to 16 px at 96 DPI.
  uiFontSize = fonts.roles.body.size * 4.0 / 3.0;

  mkOxcLanguage = withLint: {
    language_servers = lib.optional withLint "oxlint" ++ [
      "oxfmt"
      "..."
    ];
    formatter = [
      {
        language_server.name = "oxfmt";
      }
    ]
    ++ lib.optional withLint {
      code_action = "source.fixAll.oxc";
    };
    prettier.allowed = false;
  };

  oxcLanguages = lib.mapAttrs (_: mkOxcLanguage) {
    JavaScript = true;
    JSX = true;
    TypeScript = true;
    TSX = true;
    JSON = false;
    JSONC = false;
    "Vue.js" = true;
  };
in
{
  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      extraPackages = with pkgs; [
        bash-language-server
        shellcheck
        shfmt
      ];

      # Merge managed values over user settings during activation while
      # preserving unrelated Zed state and settings.
      mutableUserSettings = true;

      extensions = [
        "docker-compose"
        "dockerfile"
        "github-actions"
        "github-dark-default"
        "make"
        "markdownlint"
        "nix"
        "oxc"
        "python-requirements"
        "terraform"
        "toml"
        "typos"
        "vue"
        "zig"
      ];

      userSettings = {
        auto_update = false;
        base_keymap = "VSCode";
        vim_mode = false;

        theme = "GitHub Dark Default";
        icon_theme = "Zed (Default)";

        ui_font_family = fonts.roles.body.family;
        ui_font_size = uiFontSize;
        ui_font_weight = fonts.roles.body.weight;
        buffer_font_family = fonts.families.monospace;
        buffer_font_size = fonts.adapters.editor.size;
        buffer_font_weight = fonts.adapters.editor.weight;
        buffer_line_height.custom = fonts.adapters.editor.lineHeight;
        buffer_font_features = {
          calt = true;
          dlig = true;
          liga = true;
          ss01 = true;
          ss02 = true;
        };
        markdown_preview_font_family = fonts.roles.document.family;

        tab_size = 2;
        hard_tabs = false;
        soft_wrap = "none";
        preferred_line_length = 80;
        wrap_guides = [ ];
        show_whitespaces = "boundary";
        colorize_brackets = true;
        gutter.line_numbers = true;
        inlay_hints.enabled = true;
        show_completions_on_input = true;
        show_completion_documentation = true;
        inline_code_actions = true;
        diagnostics = {
          include_warnings = true;
          inline.enabled = false;
        };

        minimap = {
          show = "always";
          display_in = "all_editors";
          thumb = "hover";
        };
        scrollbar.show = "auto";
        tabs = {
          file_icons = true;
          git_status = true;
        };
        project_panel = {
          dock = "left";
          entry_spacing = "standard";
        };

        autosave.after_delay.milliseconds = 1000;
        format_on_save = "off";
        restore_on_startup = "last_session";
        restore_on_file_reopen = true;
        session = {
          restore_unsaved_buffers = true;
          trust_all_worktrees = false;
        };

        file_types.JSONC = [
          "json5"
          "ndjson"
        ];

        telemetry = {
          diagnostics = false;
          metrics = false;
        };

        agent_servers = {
          claude-acp = {
            type = "custom";
            command = lib.getExe pkgs.claude-agent-acp;
            args = [ ];
          };
          codex-acp = {
            type = "custom";
            command = lib.getExe pkgs.codex-acp;
            args = [ ];
          };
          cursor = {
            type = "custom";
            command = lib.getExe pkgs.cursor-cli;
            args = [ "acp" ];
          };
          opencode = {
            type = "custom";
            command = lib.getExe pkgs.opencode;
            args = [ "acp" ];
          };
        };

        git = {
          disable_git = false;
          enable_status = true;
          enable_diff = true;
        };
        diff_view_style = "split";
        git_panel.button = true;
        tasks = {
          enabled = true;
          prefer_lsp = true;
        };

        terminal = {
          shell = "system";
          working_directory = "current_project_directory";
          font_family = fonts.families.monospace;
          font_size = fonts.adapters.integratedTerminal.size;
          font_weight = fonts.adapters.integratedTerminal.weight;
          line_height.custom = fonts.adapters.integratedTerminal.lineHeight;
        };

        languages = oxcLanguages // {
          Nix = {
            language_servers = [
              "nixd"
              "!nil"
            ];
            formatter.language_server.name = "nixd";
          };
          "Shell Script".formatter.external = {
            command = lib.getExe pkgs.shfmt;
            arguments = [ ];
          };
        };

        lsp = {
          nixd = {
            binary.path = lib.getExe pkgs.nixd;
            initialization_options.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
          };
          oxlint.binary = {
            path = lib.getExe pkgs.oxlint;
            arguments = [ "--lsp" ];
          };
          oxfmt.binary = {
            path = lib.getExe pkgs.oxfmt;
            arguments = [ "--lsp" ];
          };
        };
      };

      userKeymaps = [
        {
          context = "Workspace";
          bindings.ctrl-alt-shift-a = "agent::ToggleNewThreadMenu";
        }
      ];

      userTasks = [
        {
          label = "Agent: Pi";
          command = lib.getExe pkgs.pi-coding-agent;
          cwd = "$ZED_WORKTREE_ROOT";
          use_new_terminal = true;
          allow_concurrent_runs = false;
          reveal = "always";
          hide = "never";
        }
      ];
    };
  };
}
