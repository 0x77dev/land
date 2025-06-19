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
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          # Core languages (excluding ts to avoid prettier error)
          nix.enable = true;
          markdown.enable = true;
          bash.enable = true;
          html.enable = true;
          # ts.enable = true; # Disabled due to prettier package error
          go.enable = true;
          lua.enable = true;
          python.enable = true;
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
