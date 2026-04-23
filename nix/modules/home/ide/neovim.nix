{
  inputs,
  config,
  lib,
  pkgs,
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
            picker.enabled = true;
            explorer = {
              enabled = true;
              replace_netrw = true;
            };
            picker.sources.explorer = {
              layout = {
                preset = "sidebar";
                preview = true;
              };
              auto_close = false;
              hidden = true;
              ignored = true;
              follow_file = true;
              supports_live = true;
              watch = true;
            };
          };
        };

        # Fuzzy finder
        telescope = {
          enable = true;
          keymaps = {
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

      extraPlugins = with pkgs.vimPlugins; [
        fff-nvim
      ];

      extraConfigLua = ''
        require("fff").setup({
          prompt = "  ",
          title = "Files",
          max_results = 200,
          layout = {
            width = 0.92,
            height = 0.88,
            prompt_position = "top",
            preview_position = "right",
            preview_size = 0.6,
            flex = {
              size = 140,
              wrap = "top",
            },
          },
          preview = {
            enabled = true,
            line_numbers = true,
            wrap_lines = false,
          },
          git = {
            status_text_color = true,
          },
          grep = {
            modes = { "plain", "fuzzy", "regex" },
          },
        })

        local wk = require("which-key")

        wk.add({
          { "<leader>a", group = "AI" },
          { "<leader>c", group = "Code" },
          { "<leader>e", desc = "Explorer" },
          { "<leader>f", group = "Find" },
          { "<leader>g", group = "Git" },
          { "<leader>x", group = "Diagnostics" },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(event)
            wk.add({
              { "gd", desc = "Go to definition", buffer = event.buf },
              { "gD", desc = "Go to declaration", buffer = event.buf },
              { "gi", desc = "Go to implementation", buffer = event.buf },
              { "gr", desc = "Go to references", buffer = event.buf },
              { "K", desc = "Hover documentation", buffer = event.buf },
              { "<leader>c", group = "Code", buffer = event.buf },
              { "<leader>ca", desc = "Code action", buffer = event.buf },
              { "<leader>cr", desc = "Rename symbol", buffer = event.buf },
              { "<leader>fs", desc = "Document symbols", buffer = event.buf },
              { "<leader>fS", desc = "Workspace symbols", buffer = event.buf },
            })
          end,
        })

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "snacks_picker_input",
          callback = function(event)
            local ok, picker = pcall(function()
              return Snacks.picker.get({ buf = event.buf })
            end)

            if not ok or not picker or picker.opts.source ~= "explorer" then
              return
            end

            wk.add({
              { "<CR>", desc = "Open / toggle", buffer = event.buf },
              { "<BS>", desc = "Up directory", buffer = event.buf },
              { ".", desc = "Focus cwd", buffer = event.buf },
              { "H", desc = "Toggle hidden", buffer = event.buf },
              { "I", desc = "Toggle ignored", buffer = event.buf },
              { "P", desc = "Toggle preview", buffer = event.buf },
              { "a", desc = "Add file", buffer = event.buf },
              { "c", desc = "Copy", buffer = event.buf },
              { "d", desc = "Delete", buffer = event.buf },
              { "m", desc = "Move / rename", buffer = event.buf },
              { "o", desc = "Open externally", buffer = event.buf },
              { "r", desc = "Rename", buffer = event.buf },
              { "u", desc = "Refresh", buffer = event.buf },
              { "y", desc = "Yank paths", buffer = event.buf },
            })
          end,
        })
      '';

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
        # Explorer
        {
          mode = "n";
          key = "-";
          action.__raw = "function() Snacks.explorer() end";
          options.desc = "Open explorer";
        }
        {
          mode = "n";
          key = "<leader>e";
          action.__raw = "function() Snacks.explorer() end";
          options.desc = "Toggle explorer";
        }

        # FFF
        {
          mode = "n";
          key = "<leader>ff";
          action.__raw = ''function() require("fff").find_files() end'';
          options.desc = "Find files";
        }
        {
          mode = "n";
          key = "<leader>fg";
          action.__raw = ''function() require("fff").live_grep() end'';
          options.desc = "Live grep";
        }
        {
          mode = "n";
          key = "<leader>f/";
          action.__raw = ''function() require("fff").live_grep({ query = vim.fn.expand("<cword>") }) end'';
          options.desc = "Grep current word";
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
