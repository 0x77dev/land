{ inputs, pkgs, ... }:

{
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;

        lsp = {
          enable = true;
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          trouble.enable = true;
          lspSignature.enable = false;

          # Manual TypeScript LSP configuration
          lspconfig = {
            enable = true;
            sources = {
              ts-lsp = ''
                lspconfig.ts_ls.setup {
                  capabilities = capabilities,
                  on_attach = function(client, bufnr)
                    attach_keymaps(client, bufnr);
                    client.server_capabilities.documentFormattingProvider = false;
                  end,
                  cmd = {"${pkgs.typescript-language-server}/bin/typescript-language-server", "--stdio"}
                }
              '';

              # Manual CSS LSP configuration
              css-lsp = ''
                -- enable (broadcasting) snippet capability for completion
                local css_capabilities = vim.lsp.protocol.make_client_capabilities()
                css_capabilities.textDocument.completion.completionItem.snippetSupport = true

                lspconfig.cssls.setup {
                  capabilities = css_capabilities,
                  on_attach = function(client, bufnr)
                    attach_keymaps(client, bufnr);
                    client.server_capabilities.documentFormattingProvider = false;
                  end,
                  cmd = {"${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server", "--stdio"}
                }
              '';

              # Manual Tailwind CSS LSP configuration
              tailwindcss-lsp = ''
                lspconfig.tailwindcss.setup {
                  capabilities = capabilities,
                  on_attach = attach_keymaps,
                  cmd = {"${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server", "--stdio"},
                  filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }
                }
              '';

              # Manual ESLint LSP configuration
              eslint-lsp = ''
                lspconfig.eslint.setup {
                  capabilities = capabilities,
                  on_attach = attach_keymaps,
                  cmd = {"${pkgs.vscode-langservers-extracted}/bin/vscode-eslint-language-server", "--stdio"},
                  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" }
                }
              '';
            };
          };
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          # Core languages
          nix.enable = true;
          markdown.enable = true;
          bash.enable = true;
          html.enable = true;

          go.enable = true;
          lua.enable = true;
          python.enable = true;
          yaml.enable = true;
          rust = {
            enable = true;
            crates.enable = true;
          };
        };

        # Treesitter grammars
        treesitter = {
          context.enable = true;
          grammars = [
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.fish
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.vue
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.dockerfile
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.typescript
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.javascript
            pkgs.vimPlugins.nvim-treesitter.builtGrammars.tsx
          ];
        };

        # UI
        visuals = {
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          highlight-undo.enable = true;
          indent-blankline.enable = true;
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = false;
        };

        # Core features
        autopairs.nvim-autopairs.enable = true;
        autocomplete = {
          nvim-cmp.enable = true;
        };
        snippets.luasnip.enable = true;

        filetree = {
          neo-tree = {
            enable = true;
          };
        };

        telescope.enable = true;
        git = {
          enable = true;
          gitsigns.enable = true;
        };

        binds = {
          whichKey.enable = true;
        };

        comments = {
          comment-nvim.enable = true;
        };
      };
    };
  };
}
