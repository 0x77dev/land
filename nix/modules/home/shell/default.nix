{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.shell;

  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    getExe
    optional
    unique
    ;

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  userName = config.home.username;

  commonPaths = unique (
    [
      "$HOME/go/bin"
      "$HOME/.bun/bin"
      "$HOME/.local/bin"
      "${config.home.homeDirectory}/.local/share/pnpm"
      "/run/current-system/sw/bin"
      "/run/wrappers/bin"
    ]
    ++ optional isDarwin "/opt/homebrew/bin"
    ++ optional isDarwin "/etc/profiles/per-user/${userName}/bin"
  );

  exportedPath = concatStringsSep ":" commonPaths;

  commonAliases = {
    cd = "z";
    cdi = "zi";
  };

  # $EDITOR shim that decides per invocation instead of per machine: SSH and
  # headless contexts get nvim; a real local GUI session gets Cursor (when
  # installed). Everything that respects EDITOR/VISUAL (git, kubectl,
  # crontab, ...) goes through this.
  edit = pkgs.writeShellScriptBin "edit" ''
    if [ -n "''${SSH_CONNECTION-}" ] || [ -n "''${SSH_TTY-}" ]; then
      exec nvim "$@"
    fi

    ${
      if isDarwin then
        # A local (non-SSH) shell on macOS always has a GUI session.
        "gui=1"
      else
        ''
          gui=""
          if [ -n "''${WAYLAND_DISPLAY-}" ] || [ -n "''${DISPLAY-}" ]; then
            gui=1
          fi
        ''
    }

    if [ -n "$gui" ] && command -v cursor >/dev/null 2>&1; then
      exec cursor --wait "$@"
    fi

    exec nvim "$@"
  '';

  commonAbbreviations = {
    g = "git";
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gst = "git status";
    gd = "git diff";
    gds = "git diff --staged";
    gf = "git fetch";
    gpl = "git pull";
    gps = "git push";
    tf = "terraform";
    of = "tofu";
  };
in
{
  options.modules.home.shell = {
    enable = mkEnableOption "shell";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      KEYID = config.programs.gpg.settings.default-key or "C33BFD3230B660CF147762D2BF5C81B531164955";
      PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    };

    home.packages = with pkgs; [
      edit
      bat
      btop
      coreutils
      devenv
      direnv
      eza
      fd
      ripgrep
      ast-grep
      figlet
      fzf
      glow
      hwatch
      nvd
      nh
      nix-diff
      starship
      tree
      watchexec
      yazi
      zoxide
      httpie
      oha
      curl
      bun
      nodejs_24
      pnpm
      fastfetch
      jq
      fx
      yq-go
      duckdb
    ];

    programs = {
      bash = {
        enable = true;
        # macOS still routes some terminal startup paths through Apple's Bash 3.2,
        # so keep Home Manager's generated Bash config compatible there.
        enableCompletion = !isDarwin;
        shellOptions = [
          "histappend"
          "extglob"
        ]
        ++ optional (!isDarwin) "globstar"
        ++ optional (!isDarwin) "checkjobs";
        shellAliases = commonAliases // commonAbbreviations;
        initExtra = ''
          export PATH="${exportedPath}:$PATH"
        '';
      };

      zsh = {
        enable = true;
        shellAliases = commonAliases // commonAbbreviations;
        # Cursor executes zsh non-interactively, which reads .zshenv but not .zshrc.
        # Keep the direnv hook here so directory-local environments still load.
        envExtra = ''
          eval "$(${getExe pkgs.direnv} hook zsh)"
        '';
        initContent = ''
          export PATH="${exportedPath}:$PATH"
        '';
      };

      fish = {
        enable = true;
        # fish 4.8 dropped share/fish/tools/create_manpage_completions.py,
        # breaking home-manager's build-time man-page completion generation.
        # fish falls back to parsing man pages at runtime, so nothing is lost.
        generateCompletions = false;
        shellAliases = commonAliases;
        shellAbbrs = commonAbbreviations;
        interactiveShellInit = ''
          set fish_greeting
          ${concatMapStringsSep "\n" (p: "fish_add_path -m ${p}") commonPaths}
        '';
        plugins = [
          {
            inherit (pkgs.fishPlugins.git-abbr) src;
            name = "git-abbr";
          }
          {
            inherit (pkgs.fishPlugins.autopair) src;
            name = "autopair";
          }
          {
            inherit (pkgs.fishPlugins.fifc) src;
            name = "fifc";
          }
          {
            inherit (pkgs.fishPlugins.bass) src;
            name = "bass";
          }
          {
            inherit (pkgs.fishPlugins.z) src;
            name = "z";
          }
        ];
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableZshIntegration = false;
      };

      tmux.enable = true;

      # Shell integrations (init hooks in bash/zsh/fish) are emitted by
      # home-manager; no hand-rolled `zoxide init` lines needed.
      zoxide.enable = true;

      starship = {
        enable = true;
        enableBashIntegration = false;
        enableFishIntegration = true;
        enableZshIntegration = true;
      };
    };
  };
}
