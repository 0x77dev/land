{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;
    package = pkgs.vscodium;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      userSettings = {
        "editor.fontFamily" = "'TX-02-Variable', 'TX-02', monospace";
        "editor.fontSize" = 16;
        "editor.lineHeight" = 1.5;
        "editor.fontWeight" = "400";
        "editor.fontVariations" = true;
        "editor.renderWhitespace" = "boundary";
        "editor.renderControlCharacters" = true;
        "editor.fontLigatures" = "'calt', 'liga', 'dlig', 'ss01', 'ss02'";
        "editor.tabSize" = 2;
        "editor.accessibilitySupport" = "off";
        "editor.smoothScrolling" = true;
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.largeFileOptimizations" = false;
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "always";
        };

        "terminal.integrated.fontFamily" = "'TX-02-Variable', 'TX-02', monospace";
        "terminal.integrated.fontSize" = 12;
        "terminal.integrated.fontWeight" = "400";
        "terminal.integrated.lineHeight" = 1.2;
        "terminal.integrated.letterSpacing" = 0;
        "terminal.integrated.smoothScrolling" = true;

        "workbench.colorTheme" = "GitHub Dark Default";
        "workbench.preferredLightColorTheme" = "GitHub Light Default";
        "workbench.preferredDarkColorTheme" = "GitHub Dark Default";
        "workbench.list.smoothScrolling" = true;
        "workbench.colorCustomizations" = { };

        "window.autoDetectColorScheme" = true;

        "files.autoSave" = "afterDelay";

        "git.autofetch" = true;
        "git.confirmSync" = false;

        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };

        "[javascript]" = {
          "editor.fontLigatures" = "'calt', 'liga', 'ss01'";
        };
        "[python]" = {
          "editor.fontLigatures" = "'calt', 'liga', 'dlig'";
        };
        "[rust]" = {
          "editor.fontLigatures" = true;
        };

        "json.schemaDownload.enable" = true;

        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
        "telemetry.telemetryLevel" = "off";
        "security.workspace.trust.enabled" = false;
      };

      extensions = with pkgs.vscode-extensions; [
        github.github-vscode-theme
        jnoortheen.nix-ide
        rust-lang.rust-analyzer
        golang.go
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
