{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.ide;
  fonts = config.modules.home.fonts.presentation;
  cursorPackage = pkgs.code-cursor;

  marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "colab";
      publisher = "google";
      version = "0.1.7";
      hash = "sha256-wAvmXccgIEfw9Q84F/ozJwvzo26OvehdrTy3DqKu5e8=";
    }
    {
      name = "parquet-visualizer";
      publisher = "lucien-martijn";
      version = "0.31.1";
      hash = "sha256-LSL2zhg8vZXIV+wwMypC7OzTSIWmk1TP+4T280fyovU=";
    }
    {
      name = "motion-vscode-extension";
      publisher = "motion";
      version = "5.3.0";
      hash = "sha256-mJJVA4DE8NGtODpy95iO9QXR2D/heJOMSDdLAeD0snk=";
    }
    {
      name = "vscode-jupyter-powertoys";
      publisher = "ms-toolsai";
      version = "0.1.1";
      hash = "sha256-5Tv0WrpQD1Lh2bZF3noC2pfyTHo95wQRhnnNtcMr4K4=";
    }
    {
      name = "angular-console";
      publisher = "nrwl";
      version = "18.82.0";
      hash = "sha256-KeJjyI8/3JHBa1VW+CdQtBaxP+3oaaXfiXCauxlHLv8=";
    }
    {
      name = "remote-kubernetes";
      publisher = "Okteto";
      version = "0.5.2";
      hash = "sha256-joiFeEQXjnyGIH583CCIZbqET2HKbVT+/1zD/b/AMtQ=";
    }
    {
      name = "vscode-opentofu";
      publisher = "opentofu";
      version = "0.6.0";
      hash = "sha256-BXzR1jmifawIIwA0RxnqVOGrpT5/gHV4lPIcYfqAaeM=";
    }
    {
      name = "bun-vscode";
      publisher = "oven";
      version = "0.0.32";
      hash = "sha256-VlruOHiF5/wVhVVW1rq6DEc90u3IwbxD/tpTXyphD+U=";
    }
    {
      name = "oxc-vscode";
      publisher = "oxc";
      version = "1.50.0";
      hash = "sha256-ZEL3nwq2nY776ZS6V+0r3+IAwH21vzwWpYM3zLj05sI=";
    }
    {
      name = "schemastore";
      publisher = "remcohaszing";
      version = "1.0.264";
      hash = "sha256-MYetpp5qzH7eg8Lsl1kAGgtn4+/jo0Q6gBQvZeLuHlg=";
    }
    {
      name = "opencode-v2";
      publisher = "sst-dev";
      version = "0.1.1";
      hash = "sha256-11a8JaishNyy6XkTeh6s36efdt1tSNYclOdkglx8x30=";
    }
    {
      name = "typos-vscode";
      publisher = "tekumara";
      version = "0.1.52";
      hash = "sha256-o+AQDdToXTV/pUSt2zw19hf7nwbOb4gb9dlSsB7t32E=";
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
  config = mkIf cfg.enable (
    let
      userDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/Cursor/User"
        else
          "${config.xdg.configHome}/Cursor/User";
      mutableConfigTargets = [
        "${userDir}/settings.json"
        "${userDir}/mcp.json"
        "${userDir}/keybindings.json"
        "${userDir}/tasks.json"
      ];
    in
    {
      home.activation.materializeCursorConfigs = {
        after = [ "linkGeneration" ];
        before = [ ];
        data = ''
          materialize_file() {
            local target="$1"
            local backup_path="$1.backup"
            local temp_file

            if [[ ! -L "$target" ]]; then
              return 0
            fi

            if [[ -v DRY_RUN ]]; then
              verboseEcho "Would materialize $target"
              return 0
            fi

            temp_file="$(mktemp "$HOME/.hm-cursor-config.XXXXXX")"
            cat "$target" > "$temp_file"
            chmod 0644 "$temp_file"
            mv "$temp_file" "$target"
            rm -f "$backup_path"
          }
        ''
        + lib.concatMapStringsSep "\n" (target: ''
          materialize_file ${lib.escapeShellArg target}
        '') mutableConfigTargets;
      };

      programs.cursor = {
        enable = true;
        package = cursorPackage;

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
            "editor.fontFamily" =
              "'${fonts.families.monospace}', '${fonts.families.monospaceFallback}', '${fonts.families.symbolsMonospace}', '${fonts.families.emoji}', monospace";
            "terminal.integrated.fontFamily" =
              "'${fonts.families.monospace}', '${fonts.families.monospaceFallback}', '${fonts.families.symbolsMonospace}', '${fonts.families.emoji}', monospace";
            "editor.fontSize" = fonts.adapters.editor.size;
            "editor.lineHeight" = fonts.adapters.editor.lineHeight;
            "terminal.integrated.fontSize" = fonts.adapters.integratedTerminal.size;
            "editor.fontWeight" = toString fonts.adapters.editor.weight;
            # Explicit wght variations override token-level bold. CSS weight
            # selects TX-02's named Medium face while preserving bold spans.
            "editor.fontVariations" = false;
            "editor.renderWhitespace" = "boundary";
            "editor.renderControlCharacters" = true;
            "editor.fontLigatures" = "'calt', 'liga', 'dlig', 'ss01', 'ss02'";
            "terminal.integrated.fontWeight" = toString fonts.adapters.integratedTerminal.weight;
            "terminal.integrated.fontWeightBold" = toString fonts.adapters.integratedTerminal.boldWeight;
            "terminal.integrated.lineHeight" = fonts.adapters.integratedTerminal.lineHeight;
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
              "muscle.osv.computer" = "linux";
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
            "cursor.composer.usageSummaryDisplay" = "always";
            "security.promptForRemoteFileProtocolHandling" = false;
            "redhat.telemetry.enabled" = false;
          };
        };
      };
    }
  );
}
