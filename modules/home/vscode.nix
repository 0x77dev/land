{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    package = pkgs.code-cursor;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      userSettings = {
        "editor.inlineSuggest.suppressSuggestions" = true;
        "editor.fontFamily" = "'TX-02-Variable', Menlo, Monaco, 'Courier New', monospace";
        "editor.fontLigatures" = true;
        "editor.detectIndentation" = true;
        "editor.accessibilitySupport" = "off";
        "editor.fontSize" = 16;
        "workbench.iconTheme" = "catppuccin-mocha";
        "workbench.colorTheme" = "GitHub Dark Default";
        "workbench.preferredDarkColorTheme" = "GitHub Dark Default";
        "workbench.preferredLightColorTheme" = "GitHub Light Default";
        "window.autoDetectColorScheme" = true;
        "telemetry.telemetryLevel" = "off";
        "editor.formatOnSave" = true;
        "files.autoSave" = "afterDelay";
        "cody.autocomplete.formatOnAccept" = true;
        "editor.formatOnPaste" = true;
        "editor.codeActionsOnSave" = {
          "source.organizeImports" = "explicit";
        };
        "files.autoSaveWhenNoErrors" = true;
        "rust-analyzer.cachePriming.enable" = false;
        "rust-analyzer.checkOnSave" = false;
        "terminal.integrated.profiles.osx" = {
          "bash" = {
            "path" = "bash";
            "args" = [ "-l" ];
            "icon" = "terminal-bash";
          };

          "zsh" = {
            "path" = "zsh";
            "args" = [ "-l" ];
          };
          "fish" = {
            "path" = "fish";
            "args" = [ "-l" ];
          };
        };

        "security.workspace.trust.enabled" = false;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
        "nix.formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
        "git.confirmSync" = false;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "eslint.format.enable" = true;
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "git.autofetch" = true;
        "cody.telemetry.level" = "off";
        "openctx.providers" = { };
      };

      extensions = with pkgs.vscode-extensions; [
        github.github-vscode-theme
        jnoortheen.nix-ide
        rust-lang.rust-analyzer
        vue.volar
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
        ms-python.python
        eamodio.gitlens
        github.vscode-pull-request-github
        github.vscode-github-actions
        tamasfe.even-better-toml
        bbenoist.nix
        prisma.prisma
        editorconfig.editorconfig
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        ms-vscode.hexeditor
        bradlc.vscode-tailwindcss
        jnoortheen.nix-ide
        streetsidesoftware.code-spell-checker
      ];
    };
  };
}
