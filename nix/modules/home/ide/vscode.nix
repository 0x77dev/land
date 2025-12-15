{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
  vscodePackage = pkgs.vscodium;

  extensionIds = [
    "aaron-bond.better-comments"
    "ahmetlacksdopamine.env-hider"
    "antfu.goto-alias"
    "antfu.iconify"
    "anthropic.claude-code"
    "anysphere.cursorpyright"
    "anysphere.remote-ssh"
    "arahata.linter-actionlint"
    "bierner.github-markdown-preview"
    "bierner.markdown-checkbox"
    "bierner.markdown-emoji"
    "bierner.markdown-footnotes"
    "bierner.markdown-mermaid"
    "bierner.markdown-preview-github-styles"
    "bierner.markdown-yaml-preamble"
    "bradlc.vscode-tailwindcss"
    "catppuccin.catppuccin-vsc"
    "catppuccin.catppuccin-vsc-icons"
    "charliermarsh.ruff"
    "coder.coder-remote"
    "coderabbit.coderabbit-vscode"
    "ctenbrinke.ansi16"
    "saoudrizwan.claude-dev"
    "davidanson.vscode-markdownlint"
    "dbaeumer.vscode-eslint"
    "docker.docker"
    "eamodio.gitlens"
    "editorconfig.editorconfig"
    "fnando.linter"
    "gamunu.opentofu"
    "github.github-vscode-theme"
    "github.vscode-github-actions"
    "github.vscode-pull-request-github"
    "golang.go"
    "hashicorp.terraform"
    "iliazeus.vscode-ansi"
    "jackjyq.brogrammer-plus"
    "jnoortheen.nix-ide"
    "matthewpi.caddyfile-support"
    "mechatroner.rainbow-csv"
    "mkhl.direnv"
    "ms-azuretools.vscode-docker"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-toolsai.jupyter"
    "ms-toolsai.jupyter-renderers"
    "ms-toolsai.vscode-jupyter-cell-tags"
    "ms-toolsai.vscode-jupyter-slideshow"
    "ms-vscode.hexeditor"
    "ms-vscode.remote-explorer"
    "nrwl.angular-console"
    "nuxt.mdc"
    "nuxtr.nuxtr-vscode"
    "opentofu.vscode-opentofu"
    "oven.bun-vscode"
    "prisma.prisma"
    "redhat.ansible"
    "redhat.vscode-yaml"
    "rust-lang.rust-analyzer"
    "sdras.night-owl"
    "fill-labs.dependi"
    "skellock.just"
    "sst-dev.opencode"
    "streetsidesoftware.code-spell-checker"
    "streetsidesoftware.code-spell-checker-cspell-bundled-dictionaries"
    "sumneko.lua"
    "t3dotgg.vsc-material-theme-but-i-wont-sue-you"
    "tamasfe.even-better-toml"
    "teabyii.ayu"
    "timonwong.shellcheck"
    "typescriptteam.native-preview"
    "vue.volar"
    "yzane.markdown-pdf"
    "zhuangtongfa.material-theme"
  ];

  # Cursor-only extensions; replace with VSCodium equivalents.
  extensionIdReplacements = {
    "anysphere.cursorpyright" = "ms-python.vscode-pylance";
    "anysphere.remote-ssh" = "ms-vscode-remote.remote-ssh";
  };

  normalizeExtensionId = id: extensionIdReplacements.${id} or id;
  normalizedExtensionIds = map normalizeExtensionId extensionIds;
  excludedExtensionIds = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    # nixpkgs' yzane.markdown-pdf hard-depends on ungoogled-chromium (linux-only).
    "yzane.markdown-pdf"
  ];
  effectiveExtensionIds = builtins.filter (
    id: !(builtins.elem id excludedExtensionIds)
  ) normalizedExtensionIds;

  extensionOverrides = {
    # Marketplace VSIX sometimes changes without version bump; pin hash here.
    "anthropic.claude-code" = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = {
        publisher = "anthropic";
        name = "claude-code";
        version = "2.0.50";
        sha256 = "sha256-Pd4rRLS613/zSn8Pvr/cozaIAqrG06lmUC6IxHm97XQ=";
      };
    };
  };

  extensionFromNixpkgs =
    id:
    let
      parts = lib.splitString "." id;
      publisher = builtins.elemAt parts 0;
      name = lib.concatStringsSep "." (lib.drop 1 parts);
    in
    extensionOverrides.${id} or (lib.attrByPath [ publisher name ] null pkgs.vscode-extensions);

  missingExtensionIds = lib.pipe effectiveExtensionIds [
    (builtins.filter (id: extensionFromNixpkgs id == null))
  ];

  extensions = lib.pipe effectiveExtensionIds [
    (map extensionFromNixpkgs)
    (builtins.filter (x: x != null))
  ];
in
{
  config = mkIf cfg.enable {
    warnings = lib.optionals (missingExtensionIds != [ ]) [
      "modules.home.ide.vscode: some extensions are not packaged in nixpkgs and were skipped: ${lib.concatStringsSep ", " missingExtensionIds}"
    ];

    programs.vscode = {
      enable = true;
      package = vscodePackage;
      mutableExtensionsDir = true;

      profiles.default = {
        enableMcpIntegration = true;
        inherit extensions;
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
          "[javascript]" = {
            "editor.fontLigatures" = "'calt', 'liga', 'ss01'";
          };
          "[python]" = {
            "editor.fontLigatures" = "'calt', 'liga', 'dlig'";
          };
          "[rust]" = {
            "editor.fontLigatures" = true;
          };
          "editor.tabSize" = 2;
          "workbench.colorTheme" = "GitHub Dark Default";
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "editor.accessibilitySupport" = "off";
          "files.autoSave" = "afterDelay";
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
          "editor.codeActionsOnSave" = {
            "source.fixAll" = "always";
          };
          "workbench.colorCustomizations" = { };
          "workbench.list.smoothScrolling" = true;
          "editor.smoothScrolling" = true;
          "terminal.integrated.smoothScrolling" = true;
          "editor.cursorSmoothCaretAnimation" = "on";
          "remote.SSH.remotePlatform" = {
            "media" = "linux";
            "mail" = "linux";
            "muscle" = "linux";
            "ssh main.test.mykhailo.coder" = "linux";
            "coder.test" = "linux";
            "ssh coder.tuning" = "linux";
            "mykhailo@192.168.0.42" = "linux";
            "ssh mykhailo@192.168.10.172" = "linux";
            "ssh main.trust-training.mykhailo.coder" = "linux";
            "coder.trust-training" = "linux";
            "mykhailo@192.168.0.35" = "linux";
            "mykhailo@muscle" = "linux";
            "mykhailo@muscle.0x77.computer" = "linux";
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
          "[github-actions-workflow]" = {
            "editor.defaultFormatter" = "redhat.vscode-yaml";
          };
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
