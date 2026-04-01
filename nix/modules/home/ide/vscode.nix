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

  marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "colab";
      publisher = "google";
      # renovate: datasource=vscode-marketplace depName=google/colab versioning=semver
      version = "0.1.7";
      hash = "sha256-wAvmXccgIEfw9Q84F/ozJwvzo26OvehdrTy3DqKu5e8=";
    }
    {
      name = "parquet-visualizer";
      publisher = "lucien-martijn";
      # renovate: datasource=vscode-marketplace depName=lucien-martijn/parquet-visualizer versioning=semver
      version = "0.31.1";
      hash = "sha256-LSL2zhg8vZXIV+wwMypC7OzTSIWmk1TP+4T280fyovU=";
    }
    {
      name = "motion-vscode-extension";
      publisher = "motion";
      # renovate: datasource=vscode-marketplace depName=motion/motion-vscode-extension versioning=semver
      version = "5.3.0";
      hash = "sha256-mJJVA4DE8NGtODpy95iO9QXR2D/heJOMSDdLAeD0snk=";
    }
    {
      name = "vscode-jupyter-powertoys";
      publisher = "ms-toolsai";
      # renovate: datasource=vscode-marketplace depName=ms-toolsai/vscode-jupyter-powertoys versioning=semver
      version = "0.1.1";
      hash = "sha256-5Tv0WrpQD1Lh2bZF3noC2pfyTHo95wQRhnnNtcMr4K4=";
    }
    {
      name = "angular-console";
      publisher = "nrwl";
      # renovate: datasource=vscode-marketplace depName=nrwl/angular-console versioning=semver
      version = "18.82.0";
      hash = "sha256-KeJjyI8/3JHBa1VW+CdQtBaxP+3oaaXfiXCauxlHLv8=";
    }
    {
      name = "remote-kubernetes";
      publisher = "Okteto";
      # renovate: datasource=vscode-marketplace depName=Okteto/remote-kubernetes versioning=semver
      version = "0.5.2";
      hash = "sha256-joiFeEQXjnyGIH583CCIZbqET2HKbVT+/1zD/b/AMtQ=";
    }
    {
      name = "vscode-opentofu";
      publisher = "opentofu";
      # renovate: datasource=vscode-marketplace depName=opentofu/vscode-opentofu versioning=semver
      version = "0.6.0";
      hash = "sha256-BXzR1jmifawIIwA0RxnqVOGrpT5/gHV4lPIcYfqAaeM=";
    }
    {
      name = "bun-vscode";
      publisher = "oven";
      # renovate: datasource=vscode-marketplace depName=oven/bun-vscode versioning=semver
      version = "0.0.32";
      hash = "sha256-VlruOHiF5/wVhVVW1rq6DEc90u3IwbxD/tpTXyphD+U=";
    }
    {
      name = "oxc-vscode";
      publisher = "oxc";
      # renovate: datasource=vscode-marketplace depName=oxc/oxc-vscode versioning=semver
      version = "1.50.0";
      hash = "sha256-ZEL3nwq2nY776ZS6V+0r3+IAwH21vzwWpYM3zLj05sI=";
    }
    {
      name = "schemastore";
      publisher = "remcohaszing";
      # renovate: datasource=vscode-marketplace depName=remcohaszing/schemastore versioning=semver
      version = "1.0.264";
      hash = "sha256-MYetpp5qzH7eg8Lsl1kAGgtn4+/jo0Q6gBQvZeLuHlg=";
    }
    {
      name = "opencode-v2";
      publisher = "sst-dev";
      # renovate: datasource=vscode-marketplace depName=sst-dev/opencode-v2 versioning=semver
      version = "0.1.1";
      hash = "sha256-11a8JaishNyy6XkTeh6s36efdt1tSNYclOdkglx8x30=";
    }
    {
      name = "code-spell-checker";
      publisher = "streetsidesoftware";
      # renovate: datasource=vscode-marketplace depName=streetsidesoftware/code-spell-checker versioning=semver
      version = "4.0.31";
      hash = "sha256-8F9lhHkr11XeFbVsArdVvNe6NADGkMFQJoWN0sntf5s=";
    }
    {
      name = "code-spell-checker-cspell-bundled-dictionaries";
      publisher = "streetsidesoftware";
      # renovate: datasource=vscode-marketplace depName=streetsidesoftware/code-spell-checker-cspell-bundled-dictionaries versioning=semver
      version = "2.0.12";
      hash = "sha256-EPcuATssrZyGbRICTI59ogtauLryFLirh33ypkTszJk=";
    }
  ];

  managedExtensions =
    (with pkgs.vscode-extensions; [
      bierner.markdown-mermaid
      bradlc.vscode-tailwindcss
      davidanson.vscode-markdownlint
      dbaeumer.vscode-eslint
      eamodio.gitlens
      editorconfig.editorconfig
      github.github-vscode-theme
      github.vscode-github-actions
      github.vscode-pull-request-github
      jnoortheen.nix-ide
      mkhl.shfmt
      ms-azuretools.vscode-docker
      ms-kubernetes-tools.vscode-kubernetes-tools
      ms-python.debugpy
      ms-python.python
      ms-toolsai.jupyter
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      ms-vscode.makefile-tools
      redhat.vscode-yaml
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      timonwong.shellcheck
      vue.volar
      yoavbls.pretty-ts-errors
      yzhang.markdown-all-in-one
      ziglang.vscode-zig
    ])
    ++ marketplaceExtensions;
in
{
  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = vscodePackage;

      # Keep this mutable until Cursor-only/vendor extensions are packaged
      # declaratively as well:
      # - anysphere.cursorpyright
      # - anysphere.remote-ssh
      # - TypeScriptTeam.native-preview
      mutableExtensionsDir = true;

      profiles.default = {
        enableMcpIntegration = true;
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        extensions = managedExtensions;
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
          "[javascript]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[javascriptreact]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[typescript]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[typescriptreact]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[json]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[jsonc]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "[vue]"."editor.defaultFormatter" = "oxc.oxc-vscode";
          "editor.tabSize" = 2;
          "workbench.colorTheme" = "GitHub Dark Default";
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "editor.accessibilitySupport" = "off";
          "files.autoSave" = "afterDelay";
          "[nix]"."editor.defaultFormatter" = "jnoortheen.nix-ide";
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.serverSettings" = {
            nixd = {
              formatting.command = [ "nixfmt" ];
            };
          };
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
