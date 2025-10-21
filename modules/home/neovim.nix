{ inputs, pkgs, ... }:

{
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    viAlias = true;
    vimAlias = true;

    # Colorscheme
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        transparent_background = false;
      };
    };

    # General options
    opts = {
      number = true;
      relativenumber = true;

      # Indentation
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;

      # Search
      ignorecase = true;
      smartcase = true;

      # UI
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;

      # Editing
      clipboard = "unnamedplus";
      undofile = true;
      mouse = "a";

      # Splits
      splitright = true;
      splitbelow = true;
    };

    # Globals
    globals.mapleader = " ";

    # LSP Configuration
    plugins = {
      # LSP
      lsp = {
        enable = true;

        servers = {
          # Nix - using nixd (more feature-rich than nil_ls)
          nixd = {
            enable = true;
            settings = {
              nixpkgs = {
                expr = "import <nixpkgs> { }";
              };
              formatting = {
                command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
              };
              options = {
                nixos = {
                  expr = ''(builtins.getFlake ("git+file://" + toString ./.)).nixosConfigurations.rubus.options'';
                };
                home_manager = {
                  expr = ''(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."0x77@potato".options'';
                };
              };
            };
          };

          # Alternative: nil_ls (lighter weight)
          # nil_ls = {
          #   enable = true;
          #   settings = {
          #     formatting.command = [ "${pkgs.nixfmt-rfc-style}/bin/nixfmt" ];
          #     nix.flake.autoArchive = true;
          #   };
          # };

          # TypeScript/JavaScript
          ts_ls = {
            enable = true;
          };

          # CSS
          cssls.enable = true;

          # Tailwind CSS
          tailwindcss = {
            enable = true;
            filetypes = [ "html" "css" "scss" "javascript" "javascriptreact" "typescript" "typescriptreact" "vue" "svelte" ];
          };

          # ESLint
          eslint = {
            enable = true;
          };

          # HTML
          html.enable = true;

          # Bash
          bashls.enable = true;

          # Go
          gopls.enable = true;

          # Lua
          lua_ls.enable = true;

          # Python
          pyright.enable = true;

          # YAML
          yamlls.enable = true;

          # Markdown
          marksman.enable = true;
        };

        keymaps = {
          diagnostic = {
            "]e" = "goto_next";
            "[e" = "goto_prev";
          };
          lspBuf = {
            "K" = "hover";
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "gr" = "references";
            "<leader>lr" = "rename";
            "<leader>la" = "code_action";
            "<leader>lf" = "format";
          };
        };
      };

      # Formatting
      conform-nvim = {
        enable = true;
        settings = {
          formatters_by_ft = {
            nix = [ "nixfmt" ];
            lua = [ "stylua" ];
            python = [ "black" ];
            javascript = [ "prettier" ];
            typescript = [ "prettier" ];
            typescriptreact = [ "prettier" ];
            javascriptreact = [ "prettier" ];
            html = [ "prettier" ];
            css = [ "prettier" ];
            json = [ "prettier" ];
            yaml = [ "prettier" ];
            markdown = [ "prettier" ];
          };
          format_on_save = {
            lsp_format = "fallback";
            timeout_ms = 500;
          };
        };
      };

      # Treesitter
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          incremental_selection.enable = true;
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          nix
          markdown
          markdown_inline
          bash
          html
          css
          javascript
          typescript
          tsx
          go
          lua
          python
          yaml
          rust
          fish
          vue
          dockerfile
        ];
      };

      treesitter-context.enable = true;

      # Completion with Blink (more modern than cmp)
      blink-cmp = {
        enable = true;
        settings = {
          keymap = {
            preset = "default";
            "<C-space>" = [ "show" "show_documentation" "hide_documentation" ];
            "<C-e>" = [ "hide" ];
            "<CR>" = [ "select_and_accept" "fallback" ];
            "<Tab>" = [ "select_next" "snippet_forward" "fallback" ];
            "<S-Tab>" = [ "select_prev" "snippet_backward" "fallback" ];
            "<Up>" = [ "select_prev" "fallback" ];
            "<Down>" = [ "select_next" "fallback" ];
          };
          completion = {
            list = {
              selection = "auto_insert";
            };
            menu = {
              border = "rounded";
              draw = {
                columns = [
                  [ "kind_icon" ]
                  [ "label" "label_description" ]
                  [ "kind" ]
                ];
              };
            };
            documentation = {
              auto_show = true;
              window = {
                border = "rounded";
              };
            };
          };
          sources = {
            default = [ "lsp" "path" "snippets" "buffer" ];
          };
        };
      };

      # Snippets
      luasnip.enable = true;

      # File explorer
      neo-tree = {
        enable = true;
        closeIfLastWindow = true;
        window = {
          width = 30;
          mappings = {
            "<space>" = "none";
          };
        };
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        extensions = {
          fzf-native.enable = true;
        };
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
        };
      };

      # Git integration
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = true;
          current_line_blame_opts = {
            delay = 300;
            virt_text_pos = "eol";
          };
          signs = {
            add = { text = "│"; };
            change = { text = "│"; };
            delete = { text = "_"; };
            topdelete = { text = "‾"; };
            changedelete = { text = "~"; };
            untracked = { text = "┆"; };
          };
        };
      };

      lazygit.enable = true;

      # UI enhancements
      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "catppuccin";
            component_separators = {
              left = "|";
              right = "|";
            };
            section_separators = {
              left = "";
              right = "";
            };
          };
        };
      };

      web-devicons.enable = true;
      colorizer.enable = true;
      indent-blankline = {
        enable = true;
        settings = {
          scope = {
            enabled = true;
            show_start = true;
            show_end = true;
          };
        };
      };

      # Editing enhancements
      nvim-autopairs.enable = true;
      comment.enable = true;
      which-key = {
        enable = true;
        settings = {
          delay = 300;
          spec = [
            { __unkeyed = "<leader>f"; group = "Find"; }
            { __unkeyed = "<leader>g"; group = "Git"; }
            { __unkeyed = "<leader>l"; group = "LSP"; }
            { __unkeyed = "<leader>w"; group = "Window"; }
          ];
        };
      };

      # Rust - use rustaceanvim (better than rust-analyzer alone)
      rustaceanvim.enable = true;

      # Additional useful plugins
      trouble.enable = true;
      todo-comments.enable = true;
      vim-surround.enable = true;

      # Nix-specific plugins
      nix.enable = true;
      nix-develop.enable = true;
    };

    # Keymaps
    keymaps = [
      # File explorer
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle file explorer";
      }

      # Save
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<cr>";
        options.desc = "Save file";
      }

      # Quit
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>q<cr>";
        options.desc = "Quit";
      }

      # Better window navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Go to left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Go to lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Go to upper window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Go to right window";
      }

      # Git keymaps
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>LazyGit<cr>";
        options.desc = "LazyGit";
      }
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>Gitsigns diffthis<cr>";
        options.desc = "Git diff";
      }
      {
        mode = "n";
        key = "]g";
        action = "<cmd>Gitsigns next_hunk<cr>";
        options.desc = "Next git hunk";
      }
      {
        mode = "n";
        key = "[g";
        action = "<cmd>Gitsigns prev_hunk<cr>";
        options.desc = "Previous git hunk";
      }

      # Better escape
      {
        mode = "i";
        key = "jk";
        action = "<Esc>";
        options.desc = "Escape insert mode";
      }
      {
        mode = "i";
        key = "jj";
        action = "<Esc>";
        options.desc = "Escape insert mode";
      }

      # Clear search highlighting
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options.desc = "Clear search highlight";
      }

      # Better indenting
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options.desc = "Indent left";
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options.desc = "Indent right";
      }
    ];

    # Extra plugins not available in nixvim modules
    extraPlugins = with pkgs.vimPlugins; [
      supermaven-nvim
    ];

    # Additional lua config for better experience
    extraConfigLua = ''
      -- Supermaven AI Code Completion
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<C-y>",
          clear_suggestion = "<C-]>",
          accept_word = "<C-j>",
        },
        ignore_filetypes = { "TelescopePrompt" },
        color = {
          suggestion_color = "#808080",
          cterm = 244,
        },
        log_level = "info",
        disable_inline_completion = false,
        disable_keymaps = false,
      })
      
      -- Better quickfix/location list toggle
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true, silent = true })
        end,
      })
      
      -- Highlight on yank
      vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
          vim.highlight.on_yank({ timeout = 200 })
        end,
      })
      
      -- Don't auto comment new lines
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          vim.opt.formatoptions:remove({ "c", "r", "o" })
        end,
      })
    '';
  };
}
