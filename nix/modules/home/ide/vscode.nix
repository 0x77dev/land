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
  cursorVscodeVersion = cursorPackage.vscodeVersion;
  cursorPython = pkgs.python3.withPackages (
    pythonPackages: with pythonPackages; [
      ipykernel
      jupyter
      notebook
    ]
  );
  jupyterExtension =
    if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
      pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [ (lib.getLib pkgs.stdenv.cc.cc) ];
        mktplcRef = {
          name = "jupyter";
          publisher = "ms-toolsai";
          version = "2025.9.1";
          arch = "linux-x64";
          hash = "sha256-v5WsVVbz23Dy+Bb7r3NerlUBNDWElL0yOH/oZjYicRk=";
        };
        postInstall = ''
          rm -f \
            "$out/$installPrefix/dist/node_modules/zeromq/prebuilds/linux-x64/node.napi.musl.node" \
            "$out/$installPrefix/dist/node_modules/zeromqold/prebuilds/linux-x64/node.napi.musl.node"
        '';
      }
    else
      pkgs.vscode-extensions.ms-toolsai.jupyter;
  parquetExtension = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ (lib.getLib pkgs.stdenv.cc.cc) ];
    mktplcRef = {
      name = "parquet-visualizer";
      publisher = "lucien-martijn";
      version = "0.31.1";
      hash = "sha256-LSL2zhg8vZXIV+wwMypC7OzTSIWmk1TP+4T280fyovU=";
    };
  };

  marketplaceExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "nix-ide";
      publisher = "jnoortheen";
      version = "0.5.7";
      hash = "sha256-6wIjuvMlA+mwg5gzctkfOAdaQLBy2K6YcV3kJxK3VOo=";
    }
    {
      name = "colab";
      publisher = "google";
      version = "0.1.7";
      hash = "sha256-wAvmXccgIEfw9Q84F/ozJwvzo26OvehdrTy3DqKu5e8=";
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
      mkhl.shfmt
      ms-python.debugpy
      ms-python.python
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
    ++ [
      jupyterExtension
      parquetExtension
    ]
    ++ marketplaceExtensions;

  managedExtensionSpecs = map (
    extension:
    let
      id = extension.vscodeExtUniqueId;
    in
    {
      source = "${extension}/share/vscode/extensions/${id}";
      prefix = toLower id;
      directory = "${toLower id}-${extension.version}";
    }
  ) managedExtensions;
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
      extensionsDir = "${config.home.homeDirectory}/.cursor/extensions";
    in
    {
      assertions = [
        {
          assertion =
            lib.versionAtLeast cursorVscodeVersion "1.121.0" && lib.versionOlder cursorVscodeVersion "1.122.0";
          message = "Cursor extensions were validated for VS Code API 1.121.x; re-audit them for ${cursorVscodeVersion}.";
        }
      ];

      home = {
        packages = with pkgs; [
          cargo
          cursorPython
          kubectl
          kubernetes-helm
          rustc
        ];

        activation = {
          # Cursor writes installation metadata and some extensions create runtime
          # files in their own directory. Home Manager's mutable mode otherwise
          # mixes writable state with read-only Nix-store symlinks.
          installCursorExtensions = {
            after = [ "linkGeneration" ];
            before = [ ];
            data = ''
              extensions_dir=${lib.escapeShellArg extensionsDir}

              if [[ ! -v DRY_RUN ]]; then
                ${pkgs.coreutils}/bin/mkdir -p "$extensions_dir"
              fi

              install_cursor_extension() {
                local source="$1"
                local directory="$2"
                local prefix="$3"
                local destination="$extensions_dir/$directory"
                local marker="$destination/.home-manager-source"
                local candidate
                local temp
                local target

                for candidate in "$extensions_dir/$prefix"-*; do
                  if [[ "$candidate" == "$destination" ]]; then
                    continue
                  elif [[ -L "$candidate" ]]; then
                    target="$(${pkgs.coreutils}/bin/readlink "$candidate")"
                    if [[ "$target" != /nix/store/* ]]; then
                      continue
                    fi
                  elif [[ ! -f "$candidate/.home-manager-source" ]]; then
                    continue
                  fi

                  if [[ -v DRY_RUN ]]; then
                    verboseEcho "Would remove stale managed Cursor extension $candidate"
                  else
                    ${pkgs.coreutils}/bin/rm -rf "$candidate"
                  fi
                done

                if [[ -L "$destination" ]]; then
                  target="$(${pkgs.coreutils}/bin/readlink "$destination")"
                  if [[ "$target" != /nix/store/* ]]; then
                    return 0
                  fi

                  if [[ -v DRY_RUN ]]; then
                    verboseEcho "Would replace immutable Cursor extension $directory"
                    return 0
                  fi

                  ${pkgs.coreutils}/bin/rm -f "$destination"
                elif [[ -d "$destination" ]]; then
                  if [[ ! -f "$marker" || "$(<"$marker")" == "$source" ]]; then
                    return 0
                  fi

                  if [[ -v DRY_RUN ]]; then
                    verboseEcho "Would update managed Cursor extension $directory"
                    return 0
                  fi

                  ${pkgs.coreutils}/bin/rm -rf "$destination"
                elif [[ -e "$destination" ]]; then
                  return 0
                elif [[ -v DRY_RUN ]]; then
                  verboseEcho "Would install writable Cursor extension $directory"
                  return 0
                fi

                temp="$(${pkgs.coreutils}/bin/mktemp -d "$extensions_dir/.home-manager-extension.XXXXXX")"
                ${pkgs.coreutils}/bin/cp -a --reflink=auto "$source"/. "$temp"/
                ${pkgs.coreutils}/bin/chmod -R u+w "$temp"
                printf '%s\n' "$source" > "$temp/.home-manager-source"
                ${pkgs.coreutils}/bin/mv "$temp" "$destination"
              }
            ''
            + concatMapStringsSep "\n" (extension: ''
              install_cursor_extension \
                ${lib.escapeShellArg extension.source} \
                ${lib.escapeShellArg extension.directory} \
                ${lib.escapeShellArg extension.prefix}
            '') managedExtensionSpecs;
          };

          materializeCursorConfigs = {
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
        };
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
          # Managed extensions are copied into Cursor's mutable directory by
          # installCursorExtensions so Cursor can safely write runtime metadata.
          extensions = [ ];
          userTasks = {
            version = "2.0.0";
            tasks = [
              {
                label = "Agent: Pi";
                type = "process";
                command = lib.getExe pkgs.llm-agents.pi;
                options.cwd = "\${workspaceFolder}";
                problemMatcher = [ ];
                presentation = {
                  reveal = "always";
                  focus = true;
                  panel = "dedicated";
                };
              }
            ];
          };
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
            "extensions.autoUpdate" = false;
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
            "nix.serverPath" = lib.getExe pkgs.nixd;
            "nix.serverSettings" = {
              nixd = {
                formatting.command = [ (lib.getExe pkgs.nixfmt) ];
              };
            };
            "oxc.enable" = true;
            "oxc.path.oxlint" = lib.getExe pkgs.oxlint;
            "oxc.path.oxfmt" = lib.getExe pkgs.oxfmt;
            "python.defaultInterpreterPath" = lib.getExe cursorPython;
            "rust-analyzer.server.path" = lib.getExe pkgs.rust-analyzer;
            "shellcheck.executablePath" = lib.getExe pkgs.shellcheck;
            "shfmt.executablePath" = lib.getExe pkgs.shfmt;
            "opentofu.languageServer.tofu.path" = lib.getExe pkgs.opentofu;
            "zig.path" = lib.getExe pkgs.zig;
            "zig.zls.enabled" = "on";
            "zig.zls.path" = lib.getExe pkgs.zls;
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
