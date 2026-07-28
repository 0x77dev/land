{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.zmx;
  gpgEnabled = config.modules.home.gpg.enable or false;

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  inherit
    (lib.land.shared.gpg-agent {
      inherit isDarwin;
      homeDirectory = config.home.homeDirectory;
    })
    localAgentExtraSocket
    localAgentSshSocket
    remoteAgentSocket
    remoteAgentSshSocket
    ;

  zmx = getExe cfg.package;
  fzf = getExe pkgs.fzf;

  # One picker for every shell: fzf over live sessions with a history preview.
  # Enter attaches to the highlighted session (or creates one from the typed
  # query when nothing matches); ctrl-n always creates from the query.
  zmxSelect = pkgs.writeShellScriptBin "zmx-select" ''
    tab=$(printf '\t')

    display=$(
      ${zmx} list 2>/dev/null |
        while IFS="$tab" read -r name pid clients created start_dir; do
          name=''${name#*name=}
          pid=''${pid#*pid=}
          clients=''${clients#*clients=}
          start_dir=''${start_dir#*start_dir=}
          printf '%s\t%-24s pid:%-8s clients:%-3s %s\n' "$name" "$name" "$pid" "$clients" "$start_dir"
        done
    )

    # fzf --print-query --expect output order: query, key, selection.
    output=$(
      { [ -n "$display" ] && printf '%s\n' "$display"; } | ${fzf} \
        --delimiter "$tab" \
        --with-nth=2.. \
        --print-query \
        --expect=ctrl-n \
        --height=80% \
        --reverse \
        --prompt="zmx> " \
        --header="Enter: select | Ctrl-N: create new" \
        --preview "${zmx} history {1}" \
        --preview-window=right:60%:follow
    )
    rc=$?
    # 1 = no match (the query is still usable); 130 = cancelled; >=2 = error.
    case $rc in
      0 | 1) ;;
      *) exit "$rc" ;;
    esac

    query=$(printf '%s\n' "$output" | sed -n 1p)
    key=$(printf '%s\n' "$output" | sed -n 2p)
    selected=$(printf '%s\n' "$output" | sed -n 3p)

    if [ "$key" = ctrl-n ] && [ -n "$query" ]; then
      session=$query
    elif [ -n "$selected" ]; then
      session=$(printf '%s\n' "$selected" | cut -f1)
    elif [ -n "$query" ]; then
      session=$query
    else
      exit 130
    fi

    exec ${zmx} attach "$session"
  '';

  shellHint = ''
    if [ -n "''${SSH_CONNECTION-}" ] && [ -z "''${ZMX_SESSION-}" ]; then
      zmx_session_count=$(${zmx} ls --short 2>/dev/null | wc -l)
      if [ "$zmx_session_count" -gt 0 ]; then
        printf '%s\n' "zmx: $zmx_session_count session(s) active - run zmx-select to attach" >&2
      fi
      unset zmx_session_count
    fi
  '';

  fishHint = ''
    if set -q SSH_CONNECTION; and not set -q ZMX_SESSION
      set -l zmx_session_count (count (${zmx} ls --short 2>/dev/null))
      if test "$zmx_session_count" -gt 0
        printf '%s\n' "zmx: $zmx_session_count session(s) active - run zmx-select to attach" >&2
      end
    end
  '';

  shellPrompt = ''
    if [ -n "''${ZMX_SESSION-}" ]; then
      PS1="[$ZMX_SESSION] $PS1"
    fi
  '';

  remoteSettings = mapAttrs' (
    name: remote:
    nameValuePair "${name}.*" (
      {
        HostName = remote.hostname;
        User = remote.user;
        RequestTTY = "yes";
        RemoteCommand = "zmx attach %k";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/cm-%C";
        ControlPersist = "10m";
      }
      // optionalAttrs gpgEnabled {
        IdentityAgent = localAgentSshSocket;
      }
      // optionalAttrs remote.forwardAgent {
        ForwardAgent = true;
      }
      // optionalAttrs (remote.forwardGpg && gpgEnabled) {
        RemoteForward = [
          "${remoteAgentSocket} ${localAgentExtraSocket}"
          "${remoteAgentSshSocket} ${localAgentSshSocket}"
        ];
      }
      // remote.settings
    )
  ) cfg.remotes;
in
{
  options.modules.home.zmx = {
    enable = mkEnableOption "zmx";

    package = mkOption {
      type = types.package;
      default = pkgs.zmx;
      description = "The zmx package to install.";
    };

    picker.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to install the zmx-select fzf session picker.";
    };

    hint.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to show active remote zmx sessions on shell startup.";
    };

    prompt.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to show the active zmx session in prompts.";
    };

    remotes = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            hostname = mkOption {
              type = types.str;
              description = "The remote hostname.";
            };
            user = mkOption {
              type = types.str;
              default = "mykhailo";
              description = "The remote user.";
            };
            forwardAgent = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to forward the SSH agent.";
            };
            forwardGpg = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to forward GPG agent sockets.";
            };
            settings = mkOption {
              type = types.attrs;
              default = { };
              description = "Freeform SSH settings that override the generated remote settings.";
            };
          };
        }
      );
      default = { };
      description = "SSH aliases that attach to zmx sessions.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.remotes == { } || config.programs.ssh.enable;
        message = "modules.home.zmx.remotes requires programs.ssh.enable.";
      }
    ];

    home = {
      packages = [
        cfg.package
        pkgs.autossh
      ]
      ++ optional cfg.picker.enable zmxSelect;

      # macOS periodically cleans TMPDIR, which would reap idle session sockets.
      # Linux keeps the XDG_RUNTIME_DIR default: tmpfs, correct permissions, paired with system-level linger.
      sessionVariables = mkIf isDarwin {
        ZMX_DIR = "${config.xdg.stateHome}/zmx";
      };
    };

    programs = {
      bash = {
        shellAliases.ash = "autossh -M 0 -q";
        initExtra = optionalString cfg.hint.enable shellHint + optionalString cfg.prompt.enable shellPrompt;
      };

      fish = {
        shellAbbrs.ash = "autossh -M 0 -q";
        interactiveShellInit = optionalString cfg.hint.enable fishHint;
      };

      ssh = mkIf config.programs.ssh.enable {
        # SSH matches the CLI alias (for example m.dev), not its canonical hostname,
        # so existing canonical-hostname identity and forwarding blocks do not match.
        # %k expands to that alias, making per-alias upserts shared by every client.
        # RemoteCommand uses the login shell, where home or system zmx is already on PATH.
        settings = remoteSettings;
      };

      starship.settings = mkIf config.programs.starship.enable {
        env_var.ZMX_SESSION = {
          format = "[zmx:$env_value]($style) ";
          style = "bold magenta";
          description = "zmx session name";
        };
      };

      zsh = {
        shellAliases.ash = "autossh -M 0 -q";
        initContent = optionalString cfg.hint.enable shellHint;
      };
    };
  };
}
