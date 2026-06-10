{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}.maintainers) mykhailo;

  # The VM edge to spark (host side lives in ../spark): 10.77.0.1 <> 10.77.0.2.
  hostAddress = "10.77.0.1";
  guestAddress = "10.77.0.2";

  # Models served by spark's Ollama (declaratively pulled there, see ../spark).
  # MoE small-active is the only way to be both smart and fast on the GB10's
  # 273 GB/s: the A3B primary runs ~35–50 tok/s where a dense 27B crawls at
  # ~10–14. The fallback also absorbs qwen3.6 tool-parser 500s (ollama#16383)
  # and runs compression.
  ollamaModel = "qwen3.6:35b-a3b-q8_0";
  fallbackModel = "gpt-oss:20b";
  ollamaBaseUrl = "http://${hostAddress}:11434/v1";
in
{
  # The agent workstation toolkit and the auto-generated ENVIRONMENT.md
  # briefing rendered from this config.
  imports = [ ./environment.nix ];

  networking = {
    hostName = "vasyl";
    domain = "0x77.computer";
    useNetworkd = true;
    useDHCP = false;
  };

  # Inherit the host's DNS instead of hardcoding upstreams: the guest's
  # resolved (already on) forwards to spark's stub on the tap edge (see
  # ../spark), which in turn forwards to whatever upstream spark currently
  # uses. Pointing nameservers at the host edge keeps the guest config stable
  # while the real upstreams are inherited dynamically at the host.
  networking.nameservers = [ hostAddress ];

  # No bootloader and no disk layout of its own: microvm.nix boots the kernel
  # directly, the host's /nix/store arrives as a read-only virtiofs share with
  # a writable overlay on the volume, and the volume below is the persistent
  # world.
  microvm = {
    # cloud-hypervisor: first-class aarch64, virtio-only. It supports virtiofs
    # (only 9p is unsupported), so the store share below works here.
    hypervisor = "cloud-hypervisor";

    # Half the GB10's 20 cores, a quarter of its 128 GiB unified memory:
    # generous for an agent, while host inference keeps ~96 GiB and the GPU.
    vcpu = 10;
    mem = 32768;

    interfaces = [
      {
        type = "tap";
        id = "vm-vasyl";
        mac = "02:77:00:00:00:01";
      }
    ];

    # AF_VSOCK channel: lets cloud-hypervisor signal boot readiness over
    # systemd-notify and serves as the control edge for future tooling.
    vsock.cid = 3;

    # ~1 TiB sparse root image, created and formatted by microvm.nix on first
    # start. All mutable state (hermes home, /home, /var, and the writable
    # store overlay) lives here. Snapshot trade-off: adding the virtiofs store
    # share means the clean block-only `ch-remote` snapshot story no longer
    # applies. cloud-hypervisor v52 (in 26.05) does support virtiofs/vhost-user
    # snapshots in principle, but microvm runs virtiofsd out-of-process and CH
    # snapshot/restore is currently broken on Grace/SVE (cloud-hypervisor#8057)
    # — moot on this box, and backups were deferred anyway.
    volumes = [
      {
        image = "root.img";
        mountPoint = "/";
        size = 1024 * 1024;
        fsType = "ext4";
      }
    ];

    # Share the host /nix/store read-only over virtiofs instead of building a
    # per-rebuild erofs store disk: faster rebuilds, far less disk, and the
    # guest's own closure is served straight from the host store. A /nix/store
    # share auto-disables `storeOnDisk`.
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];

    # Writable overlay on the persistent volume so the agent can `nix build` /
    # `nix shell` in-guest (see NIX.md); guest-built paths survive reboots.
    writableStoreOverlay = "/nix/.rw-store";
  };

  # Hermes Agent — the VM is the sandbox, so the terminal backend is plain
  # `local`: no coordinator/executor split, no SSH executor. The `full`
  # package variant pre-builds every optional integration (messaging, voice,
  # matrix, ...). Runtime state and secrets live under /var/lib/hermes on the
  # root volume and are hermes' own business; drop provider tokens into
  # /var/lib/hermes/.hermes/.env if messaging platforms are connected later.
  services = {
    resolved.enable = true;

    hermes-agent = {
      enable = true;
      package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.full;

      # `hermes` CLI on every PATH, sharing HERMES_HOME with the gateway. This
      # also makes config.yaml group-writable (0660) — the module's official
      # lever for keeping config mutable at runtime. The model: nix owns the
      # declared keys below (they win on rebuild via the module's deep-merge),
      # while keys the agent or a hermes-group user add on disk are preserved
      # across rebuilds. Managed mode still guards the lifecycle commands
      # (`hermes setup`/`gateway install`) — intended, since nix owns the
      # service; there is no opt-out option and none is needed for config
      # extensibility.
      addToSystemPackages = true;

      # The hermes user is defined below (with zsh) instead of by the module, so
      # the module must not also create it.
      createUser = false;

      settings = {
        # Declared default: spark's Ollama over the VM edge (documented
        # custom-endpoint flow). Deliberately not the only provider — more
        # (Vercel AI Gateway, a Codex subscription, ...) get layered in later via
        # the now-mutable config (CLI/agent) or nix without fighting this
        # baseline; that's also why the commit trailer is model-agnostic.
        model = {
          provider = "custom";
          base_url = ollamaBaseUrl;
          default = ollamaModel;
          # Any non-empty value; Ollama ignores it.
          api_key = "ollama";
          # Hermes auto-detects the model MAX (262144) from /v1/models, not the
          # server's effective window — must match spark's OLLAMA_CONTEXT_LENGTH
          # or compression fires too late and requests overflow.
          context_length = 131072;
          supports_vision = true;
        };
        fallback_providers = [
          {
            provider = "custom";
            model = fallbackModel;
            base_url = ollamaBaseUrl;
          }
        ];
        auxiliary.compression = {
          model = fallbackModel;
          base_url = ollamaBaseUrl;
          timeout = 240;
        };
        compression = {
          enabled = true;
          threshold = 0.5;
        };
        toolsets = [ "all" ];
        terminal = {
          backend = "local";
          timeout = 180;
        };
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
      };

      # Workspace docs: SOUL.md is the persona seed (Hermes manages its mutable
      # runtime copy at $HERMES_HOME/SOUL.md itself); NIX.md tells Vasyl how to
      # use Nix idiomatically on this box. A third document, ENVIRONMENT.md, is
      # auto-rendered from the live config in ./environment.nix — a
      # zero-maintenance, always-current machine briefing.
      documents = {
        "SOUL.md" = ./SOUL.md;
        "NIX.md" = ./NIX.md;
      };
    };

    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        AllowAgentForwarding = true;
        StreamLocalBindUnlink = true;
      };
    };
  };

  # Machine-wide git policy, covering both mykhailo and the hermes daemon:
  # Mykhailo's identity, no signing (no YubiKey inside the VM), and the Linux
  # kernel's AI-attribution trailer (Documentation/process/coding-assistants.rst)
  # seeded through a commit template — git's native mechanism, no wrapper
  # scripts. Templates only apply to editor-composed commits; SOUL.md instructs
  # the agent to carry the trailer on `-m` commits too.
  programs = {
    git = {
      enable = true;
      config = {
        user = {
          inherit (mykhailo) name email;
        };
        init.defaultBranch = "main";
        # Model-agnostic by design: the assistant is "vasyl" regardless of which
        # provider/model backs it over time. The kernel guidance names the agent;
        # we use the bare assistant name (no MODEL_VERSION) since the model varies.
        commit.template = toString (
          pkgs.writeText "vasyl-commit-template" ''


            Assisted-by: vasyl
          ''
        );
      };
    };

    # Foreign binaries (rustup toolchains, uv-installed wheels, npm native
    # deps) are expected on an agent workstation.
    nix-ld.enable = true;

    zsh.enable = true;
  };

  # /nix/store is an overlay: the host store (shared read-only at
  # /nix/.ro-store) is the lower layer; /nix/.rw-store on the 1 TiB volume
  # is the writable upper for in-guest `nix build`. Keep whole-store GC and
  # optimise off:
  # - GC scans the whole store dir and deletes whatever this guest's roots
  #   don't reach. It can't free the host-owned read-only lower; it would
  #   only mask those paths with overlay whiteouts (no real space freed,
  #   and risks hiding host store paths). The host GCs its own store. The
  #   in-daemon auto-GC is the same whole-store collection, so it is disarmed
  #   below with min-free/max-free = 0 (the shared nix-config arms it).
  # - optimise hard-links duplicate files, but can't link across the
  #   overlay's two filesystems and would copy read-only lower files up
  #   into the writable layer, growing it. The host already optimises.
  # This guest mounts a persistent ext4 volume at /, overriding microvm's
  # tmpfs default, so /nix/var — the Nix DB, gcroots, and profiles — persists
  # and in-guest builds stay valid across reboots. Reclaim dead upper-layer
  # paths with the scoped nix-upper-gc timer below, never whole-store GC.
  # Because the DB persists, a bare overlay wipe would desync it (paths gone,
  # the DB still believing them valid): treat an overlay wipe as disaster
  # recovery only, and reset the Nix DB along with it.
  nix = {
    gc.automatic = false;
    optimise.automatic = false;
    settings = {
      # Disarm the in-daemon auto-GC: it runs a whole-store collection over the
      # merged overlay and would whiteout-mask the host store mid-build.
      min-free = 0;
      max-free = 0;
    };
  };

  # Scoped overlay reclamation. `nix-store --delete` acts on explicit paths and
  # never walks the merged store, so (unlike whole-store GC) it cannot
  # whiteout-mask the host's read-only lower; it is liveness-checked and refuses
  # paths still reachable from any root, including the temp roots an in-flight
  # build holds on its outputs. Enumerating the overlay UPPERDIR
  # (`/nix/.rw-store/store/*`, per microvm's mounts.nix) rather than the merged
  # `/nix/store` is load-bearing: walking the merge is exactly what would feed
  # host-lower paths to `--delete` and mask them with whiteouts.
  #
  # The dead set is computed once with `nix-store --gc --print-dead` and removed
  # in one `--delete` batch, for two reasons (Nix 2.34 gc.cc):
  # - `--delete` aborts the whole invocation at the first still-live argument
  #   and refuses a path whose dead referrer is outside the requested set, so
  #   only a known-dead, referrer-closed batch deletes reliably (referrers of
  #   upper paths are themselves upper: anything registered in the guest DB
  #   after boot materializes in the upper). Per-path deletion would strand
  #   dead dependency chains.
  # - every successful `--delete` ends with a full readdir+lstat sweep of
  #   /nix/store/.links — the host's hardlink farm over virtiofs — so the
  #   number of invocations, not paths, dominates cost. One batch, one sweep.
  # `--print-dead` classifies against all roots (gcroots, profiles, /proc, temp
  # roots) without deleting any store path, and the non-blocking GC socket
  # keeps concurrent builds safe during both steps. Benign edges: deleting a
  # path that also exists in the lower (a guest rebuild duplicating a host
  # path) leaves a whiteout hiding the still-free lower copy until it is next
  # re-realized; `--print-dead`'s walk of the merged dir cleans entries that
  # don't even parse as store paths (host `tmp-*` build scratch), which over
  # the overlay is just another upper whiteout, the host file untouched. If a
  # path turns live between scan and delete, the unit fails loudly and the
  # next run reclaims the rest. Runs weekly over the upper at idle IO. Pin
  # outputs to keep with `nix build --out-link`.
  systemd = {
    # Static address on the tap edge; spark NATs us out for internet access.
    network.networks."20-lan" = {
      matchConfig.Type = "ether";
      address = [ "${guestAddress}/24" ];
      networkConfig.Gateway = hostAddress;
    };

    services.nix-upper-gc = {
      description = "Reclaim dead in-guest build outputs from the writable store overlay";
      path = [ config.nix.package ];
      serviceConfig = {
        Type = "oneshot";
        IOSchedulingClass = "idle";
      };
      script = ''
        set -euo pipefail
        shopt -s nullglob

        # Upperdir entries that are store paths: skip overlay whiteouts (char
        # devices) and anything not named <32 nix-base32 chars>-<name>; .lock,
        # .chroot and .check are suffix siblings of a path, not paths.
        declare -A upper=()
        for p in /nix/.rw-store/store/*; do
          [[ -c "$p" ]] && continue
          n="''${p##*/}"
          [[ "$n" =~ ^[0-9a-df-np-sv-z]{32}- ]] || continue
          case "$n" in
            *.lock | *.chroot | *.check) continue ;;
          esac
          upper["/nix/store/$n"]=1
        done
        [[ ''${#upper[@]} -eq 0 ]] && exit 0

        dead=$(nix-store --gc --print-dead)

        delete=()
        while IFS= read -r p; do
          [[ -n "$p" ]] || continue # an empty dead set herestrings one "" line
          [[ -n "''${upper["$p"]:-}" ]] && delete+=("$p")
        done <<< "$dead"
        [[ ''${#delete[@]} -eq 0 ]] && exit 0

        nix-store --delete "''${delete[@]}"
      '';
    };

    timers.nix-upper-gc = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # System-level self-management over D-Bus — works under the unit's
  # NoNewPrivileges because PID 1 / polkitd do the privileged work outside the
  # sandbox. Allowlisted to named units: a broad manage-units rule would also
  # authorize `systemd-run --system` (root-equivalent); this does not.
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        var units = [ "hermes-agent.service", "nix-upper-gc.service" ];
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            subject.user == "hermes" &&
            units.indexOf(action.lookup("unit")) != -1) {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # Agent daemon user. The hermes module would create this user with a bash
  # login shell via a plain (non-mkDefault) assignment, so to give it zsh
  # without mkForce we set createUser = false (above) and own the user here,
  # mirroring what the module would otherwise set.
  users = {
    groups.hermes = { };

    users = {
      hermes = {
        isSystemUser = true;
        group = "hermes";
        home = config.services.hermes-agent.stateDir;
        createHome = true;
        shell = pkgs.zsh;
        # Read the system journal (its own unit's logs included).
        extraGroups = [ "systemd-journal" ];
        # Own user-manager from boot: `systemd-run --user` jobs and `--user` timers
        # that survive gateway restarts (declarative loginctl enable-linger).
        linger = true;
      };

      mykhailo = {
        isNormalUser = true;
        description = mykhailo.name;
        extraGroups = [
          "wheel"
          "hermes"
        ];
        shell = pkgs.fish;
      };
    };
  };

  # Headless shells (the agent's terminal snapshot, raw SSH) get no PAM session
  # env; point them at the lingering user bus so `systemctl --user` and the
  # agent's own user manager are reachable. No-op where pam_systemd set it.
  environment.extraInit = ''
    if [ -z "''${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/$(id -u)" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
  '';

  # Identity model:
  #   - human login user = mykhailo (conventional Snowfall user + the
  #     mykhailo@vasyl home reusing his shared modules — same as every host);
  #   - agent daemon user = hermes (above, with zsh);
  #   - "vasyl" is purely the machine identity: hostname, SOUL.md persona, and
  #     the `Assisted-by: vasyl` trailer.
  # Git authorship stays Mykhailo (name/email, signing off, trailer present):
  # commits authored by Mykhailo from a machine called vasyl. mykhailo joins
  # the hermes group for shared, group-writable HERMES_HOME + config.yaml;
  # SSH access comes from his keys via the user-keys module.
  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  system.stateVersion = "26.05";
}
