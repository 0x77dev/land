{
  inputs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
in
{
  imports = [
    (inputs.nixvim.homeModules.default or inputs.nixvim.homeManagerModules.default)
  ];

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;

      # ── Core Options ─────────────────────────────────────────────────
      globals.mapleader = " ";
      globals.maplocalleader = " ";

      # Enable built-in editorconfig support (Neovim 0.9+)
      editorconfig.enable = true;

      opts = {
        # Line numbers
        number = true;
        relativenumber = true;
        signcolumn = "yes";

        # Tabs & indentation
        tabstop = 2;
        softtabstop = 2;
        shiftwidth = 2;
        expandtab = true;
        smartindent = true;

        # Search
        ignorecase = true;
        smartcase = true;
        hlsearch = false;
        incsearch = true;

        # Scrolling
        scrolloff = 8;
        sidescrolloff = 8;

        # Undo & backup
        undofile = true;
        swapfile = false;
        backup = false;

        # UI
        termguicolors = true;
        cursorline = true;
        wrap = false;
        splitbelow = true;
        splitright = true;

        # Performance
        updatetime = 250;
        timeoutlen = 300;

        # Mouse
        mouse = "a";
      };

      # ── Colorscheme ──────────────────────────────────────────────────
      colorschemes.github-theme = {
        enable = true;
        settings = {
          options = {
            transparent = false;
            dim_inactive = true;
          };
        };
      };
      colorscheme = "github_dark_default";

      # ── Plugins ──────────────────────────────────────────────────────
      plugins = {
        # Statusline
        lualine.enable = true;

        # Treesitter (syntax highlighting & more)
        treesitter = {
          enable = true;
          settings = {
            highlight.enable = true;
            indent.enable = true;
            incremental_selection = {
              enable = true;
              keymaps = {
                init_selection = "<C-space>";
                node_incremental = "<C-space>";
                scope_incremental = false;
                node_decremental = "<bs>";
              };
            };
          };
        };

        # Completion (blink.cmp)
        blink-cmp = {
          enable = true;
          settings = {
            keymap.preset = "default";
            appearance = {
              use_nvim_cmp_as_default = true;
              nerd_font_variant = "mono";
            };
            sources = {
              default = [
                "lsp"
                "path"
                "buffer"
              ];
            };
            signature.enabled = true;
            completion = {
              documentation = {
                auto_show = true;
                auto_show_delay_ms = 200;
              };
              ghost_text.enabled = true;
            };
          };
        };

        # Snippets
        luasnip.enable = true;

        snacks = {
          enable = true;
          settings = {
            input.enabled = true;
          };
        };

        # Fuzzy finder
        telescope = {
          enable = true;
          keymaps = {
            "<leader>ff" = {
              action = "find_files";
              options.desc = "Find files";
            };
            "<leader>fg" = {
              action = "live_grep";
              options.desc = "Live grep";
            };
            "<leader>fb" = {
              action = "buffers";
              options.desc = "Buffers";
            };
            "<leader>fh" = {
              action = "help_tags";
              options.desc = "Help tags";
            };
            "<leader>fr" = {
              action = "oldfiles";
              options.desc = "Recent files";
            };
            "<leader>fd" = {
              action = "diagnostics";
              options.desc = "Diagnostics";
            };
            "<leader>fs" = {
              action = "lsp_document_symbols";
              options.desc = "Document symbols";
            };
            "<leader>fS" = {
              action = "lsp_workspace_symbols";
              options.desc = "Workspace symbols";
            };
            "<leader>/" = {
              action = "current_buffer_fuzzy_find";
              options.desc = "Search in buffer";
            };
          };
          extensions = {
            fzf-native.enable = true;
            ui-select.enable = true;
          };
        };

        # File browser
        oil = {
          enable = true;
          settings = {
            default_file_explorer = true;
            delete_to_trash = true;
            skip_confirm_for_simple_edits = true;
            view_options = {
              show_hidden = true;
            };
            keymaps = {
              "g?" = "actions.show_help";
              "<CR>" = "actions.select";
              "<C-v>" = "actions.select_vsplit";
              "<C-s>" = "actions.select_split";
              "<C-t>" = "actions.select_tab";
              "<C-p>" = "actions.preview";
              "<C-c>" = "actions.close";
              "<C-r>" = "actions.refresh";
              "-" = "actions.parent";
              "_" = "actions.open_cwd";
              "`" = "actions.cd";
              "~" = "actions.tcd";
              "gs" = "actions.change_sort";
              "gx" = "actions.open_external";
              "g." = "actions.toggle_hidden";
            };
          };
        };

        # Git integration
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = true;
            current_line_blame_opts = {
              delay = 500;
              virt_text_pos = "eol";
            };
            signs = {
              add.text = "│";
              change.text = "│";
              delete.text = "_";
              topdelete.text = "‾";
              changedelete.text = "~";
            };
          };
        };

        # Keybinding discoverability
        which-key = {
          enable = true;
          settings = {
            delay = 200;
            icons = {
              mappings = true;
              keys = { };
            };
            spec = [
              {
                __unkeyed-1 = "<leader>f";
                group = "Find";
              }
              {
                __unkeyed-1 = "<leader>c";
                group = "Code";
              }
              {
                __unkeyed-1 = "<leader>g";
                group = "Git";
              }
              {
                __unkeyed-1 = "<leader>x";
                group = "Diagnostics";
              }
              {
                __unkeyed-1 = "<leader>a";
                group = "AI (OpenCode)";
              }
            ];
          };
        };

        # Icons
        web-devicons.enable = true;

        # Mini plugins
        mini = {
          enable = true;
          modules = {
            pairs = { };
            surround = { };
            ai = { };
          };
        };

        # Indentation guides
        indent-blankline = {
          enable = true;
          settings = {
            indent = {
              char = "│";
            };
            scope = {
              enabled = true;
              show_start = true;
            };
          };
        };

        # Formatting
        conform-nvim = {
          enable = true;
          settings = {
            format_on_save = {
              timeout_ms = 500;
              lsp_fallback = true;
            };
            formatters_by_ft = {
              nix = [ "nixfmt" ];
              lua = [ "stylua" ];
              python = [ "ruff_format" ];
              javascript = [
                "oxfmt"
                "oxlint"
              ];
              javascriptreact = [
                "oxfmt"
                "oxlint"
              ];
              typescript = [
                "oxfmt"
                "oxlint"
              ];
              typescriptreact = [
                "oxfmt"
                "oxlint"
              ];
              json = [ "oxfmt" ];
              jsonc = [ "oxfmt" ];
              yaml = [ "prettier" ];
              markdown = [ "prettier" ];
              rust = [ "rustfmt" ];
              vue = [ "oxfmt" ];
              "_" = [ "trim_whitespace" ];
            };
          };
        };

        # Better diagnostics display
        trouble = {
          enable = true;
          settings = {
            modes = {
              diagnostics = {
                auto_close = true;
              };
            };
          };
        };

        # Comments
        comment.enable = true;

        # Autopairs for treesitter
        nvim-autopairs.enable = true;

        # Highlight todo comments
        todo-comments.enable = true;

        opencode = {
          enable = true;
          autoLoad = true;
          settings = {
            auto_reload = true;
            lsp = {
              enabled = true;
            };
          };
        };
      };

      # ── LSP ──────────────────────────────────────────────────────────
      plugins.lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          lua_ls.enable = true;
          oxlint.enable = true;
          oxfmt.enable = true;
          docker_language_server.enable = true;
          docker_compose_language_server.enable = true;
          jsonls.enable = true;
          yamlls.enable = true;
          markdown_oxide.enable = true;
          vue_ls.enable = true;
          ts_ls.enable = true;
          tailwindcss.enable = true;
          ruff.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
        };
      };

      # ── Keymaps ──────────────────────────────────────────────────────
      keymaps = [
        # Oil
        {
          mode = "n";
          key = "-";
          action = "<cmd>Oil<cr>";
          options.desc = "Open file browser";
        }

        # Format
        {
          mode = "n";
          key = "<leader>cf";
          action.__raw = ''function() require("conform").format() end'';
          options.desc = "Format buffer";
        }

        # LSP keymaps
        {
          mode = "n";
          key = "gd";
          action.__raw = "vim.lsp.buf.definition";
          options.desc = "Go to definition";
        }
        {
          mode = "n";
          key = "gD";
          action.__raw = "vim.lsp.buf.declaration";
          options.desc = "Go to declaration";
        }
        {
          mode = "n";
          key = "gi";
          action.__raw = "vim.lsp.buf.implementation";
          options.desc = "Go to implementation";
        }
        {
          mode = "n";
          key = "gr";
          action.__raw = "vim.lsp.buf.references";
          options.desc = "Go to references";
        }
        {
          mode = "n";
          key = "K";
          action.__raw = "vim.lsp.buf.hover";
          options.desc = "Hover documentation";
        }
        {
          mode = "n";
          key = "<leader>ca";
          action.__raw = "vim.lsp.buf.code_action";
          options.desc = "Code action";
        }
        {
          mode = "n";
          key = "<leader>cr";
          action.__raw = "vim.lsp.buf.rename";
          options.desc = "Rename symbol";
        }
        {
          mode = "n";
          key = "<leader>xd";
          action.__raw = "vim.diagnostic.open_float";
          options.desc = "Line diagnostics";
        }
        {
          mode = "n";
          key = "[d";
          action.__raw = "vim.diagnostic.goto_prev";
          options.desc = "Previous diagnostic";
        }
        {
          mode = "n";
          key = "]d";
          action.__raw = "vim.diagnostic.goto_next";
          options.desc = "Next diagnostic";
        }

        # Better window navigation
        {
          mode = "n";
          key = "<C-h>";
          action = "<C-w>h";
          options.desc = "Move to left window";
        }
        {
          mode = "n";
          key = "<C-j>";
          action = "<C-w>j";
          options.desc = "Move to lower window";
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<C-w>k";
          options.desc = "Move to upper window";
        }
        {
          mode = "n";
          key = "<C-l>";
          action = "<C-w>l";
          options.desc = "Move to right window";
        }

        # Buffer navigation
        {
          mode = "n";
          key = "<S-h>";
          action = "<cmd>bprevious<cr>";
          options.desc = "Previous buffer";
        }
        {
          mode = "n";
          key = "<S-l>";
          action = "<cmd>bnext<cr>";
          options.desc = "Next buffer";
        }

        # Clear search highlight
        {
          mode = "n";
          key = "<Esc>";
          action = "<cmd>nohlsearch<cr>";
          options.desc = "Clear search highlight";
        }

        # Trouble
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          options.desc = "Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xX";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          options.desc = "Buffer diagnostics (Trouble)";
        }

        # Git (gitsigns)
        {
          mode = "n";
          key = "<leader>gb";
          action = "<cmd>Gitsigns blame_line<cr>";
          options.desc = "Blame line";
        }
        {
          mode = "n";
          key = "<leader>gp";
          action = "<cmd>Gitsigns preview_hunk<cr>";
          options.desc = "Preview hunk";
        }
        {
          mode = "n";
          key = "]h";
          action = "<cmd>Gitsigns next_hunk<cr>";
          options.desc = "Next hunk";
        }
        {
          mode = "n";
          key = "[h";
          action = "<cmd>Gitsigns prev_hunk<cr>";
          options.desc = "Previous hunk";
        }

        # Better indenting in visual mode
        {
          mode = "v";
          key = "<";
          action = "<gv";
        }
        {
          mode = "v";
          key = ">";
          action = ">gv";
        }

        # Move lines
        {
          mode = "n";
          key = "<A-j>";
          action = "<cmd>m .+1<cr>==";
          options.desc = "Move line down";
        }
        {
          mode = "n";
          key = "<A-k>";
          action = "<cmd>m .-2<cr>==";
          options.desc = "Move line up";
        }
        {
          mode = "v";
          key = "<A-j>";
          action = ":m '>+1<cr>gv=gv";
          options.desc = "Move selection down";
        }
        {
          mode = "v";
          key = "<A-k>";
          action = ":m '<-2<cr>gv=gv";
          options.desc = "Move selection up";
        }

        # OpenCode AI
        {
          mode = "n";
          key = "<leader>aa";
          action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
          options.desc = "Ask OpenCode";
        }
        {
          mode = "v";
          key = "<leader>aa";
          action.__raw = ''function() require("opencode").ask("@this: ", { submit = true }) end'';
          options.desc = "Ask OpenCode (selection)";
        }
        {
          mode = "n";
          key = "<leader>as";
          action.__raw = ''function() require("opencode").select() end'';
          options.desc = "Select OpenCode action";
        }
        {
          mode = "n";
          key = "<leader>at";
          action.__raw = ''function() require("opencode").toggle() end'';
          options.desc = "Toggle OpenCode";
        }
        {
          mode = "n";
          key = "<leader>ae";
          action.__raw = ''function() require("opencode").prompt("explain") end'';
          options.desc = "Explain with OpenCode";
        }
        {
          mode = "v";
          key = "<leader>ae";
          action.__raw = ''function() require("opencode").prompt("explain") end'';
          options.desc = "Explain with OpenCode (selection)";
        }
        {
          mode = "n";
          key = "<leader>ar";
          action.__raw = ''function() require("opencode").prompt("review") end'';
          options.desc = "Review with OpenCode";
        }
      ];
    };
  };
}
