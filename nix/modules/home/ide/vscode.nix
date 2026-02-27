{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
  vscodePackage = pkgs.code-cursor;
in
{
  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = vscodePackage;
      mutableExtensionsDir = true;

      profiles.default = {
        enableMcpIntegration = true;
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        userSettings = {
          "editor.fontFamily" = "'TX-02-Variable', 'TX-02', monospace";
          "terminal.integrated.fontFamily" = "'TX-02-Variable', 'TX-02', monospace";
          "editor.fontSize" = 16;
          "editor.lineHeight" = 1.5;
          "terminal.integrated.fontSize" = 12;
          "editor.fontWeight" = "400";
          "editor.fontVariations" = true;
          "editor.renderWhitespace" = "boundary";
          "editor.renderControlCharacters" = true;
          "editor.fontLigatures" = "'calt', 'liga', 'dlig', 'ss01', 'ss02'";
          "terminal.integrated.fontWeight" = "400";
          "terminal.integrated.lineHeight" = 1.2;
          "terminal.integrated.letterSpacing" = 0;
          "[javascript]"."editor.fontLigatures" = "'calt', 'liga', 'ss01'";
          "[python]"."editor.fontLigatures" = "'calt', 'liga', 'dlig'";
          "[rust]"."editor.fontLigatures" = true;
          "editor.tabSize" = 2;
          "workbench.colorTheme" = "GitHub Dark Default";
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "editor.accessibilitySupport" = "off";
          "files.autoSave" = "afterDelay";
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.codeActionsOnSave"."source.fixAll" = "always";
          "workbench.colorCustomizations" = { };
          "workbench.list.smoothScrolling" = true;
          "editor.smoothScrolling" = true;
          "terminal.integrated.smoothScrolling" = true;
          "editor.cursorSmoothCaretAnimation" = "on";
          "remote.SSH.remotePlatform" = {
            "muscle.0x77.computer" = "linux";
            "*.coder" = "linux";
            "coder.*" = "linux";
          };
          "workbench.preferredLightColorTheme" = "GitHub Light Default";
          "workbench.preferredDarkColorTheme" = "GitHub Dark Default";
          "window.autoDetectColorScheme" = true;
          "docker.extension.enableComposeLanguageServer" = false;
          "typescript.updateImportsOnFileMove.enabled" = "always";
          "githubPullRequests.pullBranch" = "never";
          "[dockercompose]" = {
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
            "editor.autoIndent" = "advanced";
            "editor.defaultFormatter" = "redhat.vscode-yaml";
          };
          "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
          "javascript.updateImportsOnFileMove.enabled" = "always";
          "files.associations" = {
            "*.md" = "markdown";
            "*.json5" = "jsonc";
            "*.ndjson" = "jsonc";
          };
          "cursor.composer.queueMessageDefaultBehavior" = "queue";
          "remote.autoForwardPortsSource" = "hybrid";
          "claudeCode.preferredLocation" = "panel";
          "cursor.composer.usageSummaryDisplay" = "always";
          "security.promptForRemoteFileProtocolHandling" = false;
          "redhat.telemetry.enabled" = false;
        };
      };
    };
  };
}
