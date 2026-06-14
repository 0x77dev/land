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
  # The primary is the abliterated, Claude-4.7-distilled Qwen3.6-35B-A3B — same
  # MoE small-active arch, the only way to be both smart and fast on the GB10's
  # 273 GB/s: the A3B primary runs ~35–50 tok/s where a dense 27B crawls at
  # ~10–14. The gpt-oss:20b fallback also absorbs qwen3.6 tool-parser 500s
  # ~10–14. Keep gpt-oss:20b as a local fallback for parser/runtime quirks, but
  # use Qwen3-4B-2507 for compression: 256K native context at ~2.5 GB Q4_K_M.
  ollamaModel = "huihui_ai/Qwen3.6-abliterated:35b-Claude-4.7";
  fallbackModel = "gpt-oss:20b";
  compressionModel = "qwen3:4b-instruct-2507-q4_K_M";
  ollamaBaseUrl = "http://${hostAddress}:11434/v1";

  # VM-local secret env file — nothing secret in Nix, no secret-management
  # machinery. External credentials are filled by hand (see the README,
  # "Secrets"); internal self-secrets are generated write-once by the
  # hermes-secret-init oneshot below. Deliberately NOT in NIX.md, which is
  # surfaced to the agent — it must not carry the secret store layout (soul
  # inspectability principle). The hermes module merges this file into
  # $HERMES_HOME/.env on every activation (absent/empty is tolerated).
  hermesSecretEnv = "/var/lib/hermes/secret.env";

  searxngPort = 8888;
  hermesWebhookPort = 8644;
  hermesDashboardPort = 9119;
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

    # AF_VSOCK channel: boot-readiness signaling to the host plus shell access
    # without touching the network path. Setting a cid makes the runner
    # advertise supportsNotifySocket, which flips the host's microvm@vasyl
    # unit to Type=notify: the host then REQUIRES the guest to send READY=1
    # over vsock (host CID 2 port 8888, socat-bridged into the unit's
    # NOTIFY_SOCKET) — otherwise it kills the healthy VM at startupTimeout
    # (150s) and restart-loops forever.
    vsock = {
      cid = 3;
      # `microvm -s vasyl -l mykhailo` from spark (root login is off here, so
      # the command's default `-l root` is refused by sshd). The listener is
      # sshd-vsock.socket from systemd-ssh-generator, which only materializes
      # when /dev/vsock + a CID exist at *generator* time — see the initrd
      # module below.
      ssh.enable = true;
    };

    # ...and that READY=1 needs a working delivery path. microvm.nix tells
    # guest systemd where to notify via an SMBIOS Type 11 OEM-string
    # credential (--platform oem_strings=[io.systemd.credential:...]), but
    # cloud-hypervisor implements SMBIOS on x86_64 only (arch/src/x86_64/
    # smbios.rs) — on aarch64 the string silently never reaches the guest,
    # PID 1 never learns of vmm.notify_socket, and the boot times out as
    # above. Hand PID 1 the same credential over the kernel cmdline instead:
    # systemd imports systemd.set_credential= into the same system-credential
    # set it reads vmm.notify_socket from (core/import-creds.c), so this is
    # transport-equivalent to the SMBIOS string. Nothing secret here — it is
    # only the notify address, fine in /proc/cmdline.
    kernelParams = [ "systemd.set_credential=vmm.notify_socket:vsock-stream:2:8888" ];

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

  # The virtio vsock transport is =m in the stock kernel and BOTH in-guest
  # vsock consumers need it earlier than udev coldplug or modules-load can
  # guarantee:
  #   - systemd-ssh-generator probes AF_VSOCK + /dev/vsock CID at generator
  #     time — before ANY unit runs — and silently skips creating
  #     sshd-vsock.socket (the `microvm -s` listener) if it is not there yet;
  #   - PID 1 sends READY=1 exactly once, at startup-finished.
  # Stage 1 is the only point early enough for the generator, so force-load
  # it in the initrd (virtio_pci is already there for the root volume, so the
  # device probes and gets its CID before stage 2 hands off).
  boot.initrd.kernelModules = [ "vmw_vsock_virtio_transport" ];

  # Tailscale needs a TUN device. /dev/net/tun is a guest-kernel device
  # (independent of cloud-hypervisor) that appears once the stock kernel's
  # tun=m module is loaded, so just load it at boot — CAP_NET_ADMIN is a
  # non-issue since tailscaled runs as root in this full guest. If a future
  # kernel/microvm combo ever lacks TUN, fall back to userspace networking via
  # `services.tailscale.interfaceName = "userspace-networking"`.
  boot.kernelModules = [ "tun" ];

  # Hermes Agent — the VM is the sandbox, so the terminal backend is plain
  # `local`: no coordinator/executor split, no SSH executor. The `full`
  # package variant pre-builds every optional integration (messaging, voice,
  # matrix, ...). Runtime state lives under /var/lib/hermes on the root volume
  # and is hermes' own business. Secrets do NOT go into $HERMES_HOME/.env by
  # hand: with environment/environmentFiles set, the module rewrites that file
  # wholesale on every activation. Provider/platform tokens (Matrix, the API
  # server key, future key-gated features) go into the VM-local secret file
  # (hermesSecretEnv above) instead — environmentFiles merges it into .env.
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
        # Declared default: GPT-5.5 through the OpenAI Codex subscription, with
        # OpenCode Go as a second paid route and spark's Ollama endpoint as the
        # offline/local safety net. Credentials live in Hermes auth, not Nix;
        # the local custom endpoint keeps its dummy key because Ollama ignores it.
        model = {
          provider = "openai-codex";
          default = "gpt-5.5";
        };
        fallback_providers = [
          {
            provider = "opencode-go";
            model = "kimi-k2.6";
          }
          {
            provider = "custom";
            model = ollamaModel;
            base_url = ollamaBaseUrl;
            api_key = "ollama";
            # Hermes auto-detects the model MAX (262144) from /v1/models, not the
            # server's effective window — must match spark's OLLAMA_CONTEXT_LENGTH
            # or compression fires too late and requests overflow.
            context_length = 262144;
            supports_vision = true;
          }
          {
            provider = "custom";
            model = fallbackModel;
            base_url = ollamaBaseUrl;
            api_key = "ollama";
            context_length = 262144;
          }
        ];
        # Give Hermes' /model picker a named row for spark's Ollama endpoint.
        # The fallback entries above are runtime-only; custom_providers is what
        # model-switch inventory groups and live-discovers through /v1/models.
        custom_providers = [
          {
            name = "Ollama";
            base_url = ollamaBaseUrl;
            api_key = "ollama";
            api_mode = "chat_completions";
            discover_models = true;
          }
        ];
        auxiliary = {
          compression = {
            provider = "custom";
            model = compressionModel;
            base_url = ollamaBaseUrl;
            timeout = 240;
          };
          # Smart approval uses Hermes' auxiliary task router. Pin it to the
          # same Codex subscription/model as the main agent instead of letting
          # auto-provider selection drift to a weaker or unfunded backend.
          approval = {
            provider = "openai-codex";
            model = "gpt-5.5";
            timeout = 30;
          };
        };
        approvals = {
          mode = "smart";
          cron_mode = "deny";
        };
        compression = {
          enabled = true;
          threshold = 0.5;
        };
        # Tool exposure is per platform in current Hermes. The legacy
        # top-level `toolsets` key is deprecated/ignored; keep the active
        # platform defaults explicit so Matrix, API Server, cron, and the CLI
        # retain their intended surfaces without relying on stale compatibility
        # shims.
        platform_toolsets = {
          cli = [ "hermes-cli" ];
          matrix = [ "hermes-matrix" ];
          api_server = [ "hermes-api-server" ];
          cron = [ "hermes-cron" ];
          webhook = [ "hermes-webhook" ];
        };

        # Cursor-like multitasking in Hermes terms: native subagent delegation
        # is enabled, bounded, and flat by default. The main agent decides when
        # a task has real parallel structure; children inherit the primary
        # model/provider route and cannot auto-approve dangerous commands.
        delegation = {
          max_iterations = 50;
          max_concurrent_children = 3;
          max_spawn_depth = 1;
          orchestrator_enabled = true;
          subagent_auto_approve = false;
          inherit_mcp_toolsets = true;
        };

        # Keep durable scheduled work serialized until a job explicitly proves
        # it is safe to parallelize; dangerous cron commands remain denied by
        # approvals.cron_mode above.
        cron.max_parallel_jobs = 1;

        # Keep the kanban dispatcher visible in declarative config, but avoid
        # surprising autonomous decomposition until dedicated worker profiles
        # and isolated branch routing are deliberately added.
        kanban = {
          dispatch_in_gateway = true;
          auto_decompose = false;
          max_in_progress_per_profile = 1;
        };

        terminal = {
          backend = "local";
          # Canonical home of the agent's working directory (the gateway
          # bridges it to TERMINAL_CWD). Supersedes the deprecated
          # MESSAGING_CWD the module still injects into the unit env —
          # scrubbed via UnsetEnvironment below.
          cwd = config.services.hermes-agent.workingDirectory;
          timeout = 180;
        };
        memory = {
          memory_enabled = true;
          user_profile_enabled = true;
        };
        # web_search via the local SearXNG below (keyless, self-hosted).
        web.search_backend = "searxng";
        # Webhooks are declared in config.yaml, not env-only, because the
        # `hermes webhook` management CLI currently checks config state when
        # deciding whether subscriptions may be managed. The secret remains in
        # hermesSecretEnv below so no credential enters Nix.
        platforms.webhook = {
          enabled = true;
          extra = {
            host = "0.0.0.0";
            port = hermesWebhookPort;
          };
        };
        # Voice — STT (Parakeet NIM) and TTS (Kokoro) run on spark's GPU and
        # serve OpenAI-compatible endpoints on the tap edge (see ../spark).
        # Both conventional voice tools and Hermes' realtime voice-mode issue
        # one-shot client-side calls (/v1/audio/transcriptions and
        # /v1/audio/speech), so no WebSocket/Realtime server is needed. GPU
        # budget beside the ~24 GB primary model and this VM's 32 GiB:
        # Parakeet ~3–6 GiB at one-shot batch sizes (NVIDIA's support matrix
        # lists ~26 GiB worst-case at the profile's max batch) plus Kokoro
        # ~1–2 GiB — within the GB10's 128 GiB unified-memory headroom.
        stt = {
          provider = "openai";
          openai = {
            # Any non-empty value; the Parakeet shim is unauthenticated.
            api_key = "local";
            base_url = "http://${hostAddress}:8102/v1";
            # The shim accepts the normal OpenAI multipart shape and ignores
            # the model because raw Parakeet NIM selects its profile by
            # language internally.
            model = "parakeet";
          };
        };
        tts = {
          provider = "openai";
          openai = {
            base_url = "http://${hostAddress}:8101/v1";
            # Alternates (am_fenrir, am_puck) switch by name once their
            # weights are added to the shim's voice map in ../spark.
            voice = "am_michael";
            model = "kokoro";
          };
        };
        # Bundled plugins are opt-in by design. Enable only the pieces this VM
        # intentionally operates: disk-cleanup for session temp-file GC, and
        # basic dashboard auth so the tailnet-exposed dashboard can bind
        # non-loopback without falling back to --insecure.
        plugins.enabled = [
          "dashboard_auth/basic"
          "disk-cleanup"
        ];
      };

      # Non-secret env, merged into $HERMES_HOME/.env at activation. The HTTP
      # API server activates from env alone; its mandatory API_SERVER_KEY is
      # self-generated into the secret file by hermes-secret-init below (the
      # adapter just stays down, logged, until the key reaches .env).
      environment = {
        API_SERVER_ENABLED = "true";
        WEBHOOK_ENABLED = "true";
        WEBHOOK_PORT = toString hermesWebhookPort;
        # Dashboard CLI defaults to 9119/127.0.0.1; keep the values explicit so
        # the Tailscale route and service agree if the port ever moves.
        HERMES_DASHBOARD_PORT = toString hermesDashboardPort;
        SEARXNG_URL = "http://127.0.0.1:${toString searxngPort}";
        # The TTS client resolves its API key from env only (config is not
        # consulted); any non-empty value — the kokoro shim doesn't check it.
        VOICE_TOOLS_OPENAI_KEY = "local";
      };

      # Secrets: external credentials are manually filled on the VM (see the
      # README); internal ones come from hermes-secret-init below. Matrix
      # creds in this file are also what *enables* the Matrix channel: the
      # gateway turns a platform on purely from its env vars; there is no
      # config.yaml switch.
      environmentFiles = [ hermesSecretEnv ];

      # The hermes wrapper ships only node/ffmpeg/ripgrep/git; the local
      # browser toolset needs a system chromium on PATH (merges with the
      # workstation list from ./environment.nix).
      extraPackages = [ pkgs.chromium ];

      # Workspace reference docs — `documents` installs files into the agent's
      # workingDirectory and nothing else reads them into the prompt. NIX.md
      # tells Vasyl how to use Nix idiomatically on this box; ENVIRONMENT.md is
      # auto-rendered from the live config in ./environment.nix — a
      # zero-maintenance, always-current machine briefing. SOUL.md is
      # deliberately NOT here: the persona file Hermes actually loads lives at
      # $HERMES_HOME/SOUL.md and is seeded via tmpfiles below.
      documents = {
        "NIX.md" = ./NIX.md;
      };
    };

    # SearXNG (the nixpkgs package is the module default), serving Hermes'
    # web_search on loopback. Results require vasyl's NAT'd outbound internet
    # through spark — without it the engines all time out. The bot-protection
    # limiter (and its valkey/redis dependency) stays at its default OFF: it
    # exists for public instances, and this one is loopback-only. SearXNG
    # refuses to start with its placeholder secret_key, but the key only
    # signs session cookies/proxy URLs — no role on a loopback, single-consumer
    # instance — so a trivial inline value beats a secret file here.
    searx = {
      enable = true;
      settings = {
        server.port = searxngPort;
        server.secret_key = "vasyl-local";
        # Hermes calls /search?format=json; the default formats allow only
        # html, which 403s JSON requests.
        search.formats = [
          "html"
          "json"
        ];
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

    # Tailscale — vasyl as its own tailnet node, reachable directly over
    # Tailscale SSH instead of always SSH-jumping via spark. Purely additive:
    # the tap edge and the `microvm -s`/spark jump stay as-is. Mirrors spark's
    # plain `enable`, plus openFirewall for the inbound tunnel port. Auth is a
    # one-time manual `sudo tailscale up --ssh` (interactive browser login) —
    # no authKeyFile, so the module's tailscaled-autoconnect unit never exists
    # and extraUpFlags (consumed only by that autoconnect) would be dead
    # config; `--ssh` rides the manual `up` instead. That outbound login needs
    # vasyl's NAT'd internet through spark (the externalInterface fix in
    # ../spark). Node state persists on the volume, so SSH stays reachable
    # across reboots without re-auth.
    tailscale = {
      enable = true;
      openFirewall = true;
      # Webhooks intentionally use public node-level Funnel (`AllowFunnel`),
      # because external systems need to call them. Dashboard/control surfaces
      # stay off Funnel and are exposed only on the tailnet below.
      funnel = {
        enable = true;
        target = "http://127.0.0.1:${toString hermesWebhookPort}";
      };
    };
  };

  # Hermes dashboard WebUI. It is deliberately NOT exposed through Tailscale
  # Funnel: it binds on the VM so Hermes' non-loopback OAuth gate engages, and
  # the NixOS firewall below admits the port only from the tailnet interface.
  # The dashboard password is intentionally local-only: the dashboard is a
  # tailnet control plane, not public ingress. hermes-secret-init below writes
  # the basic-auth password once into ${hermesSecretEnv}; read it there instead
  # of putting credentials in Nix. Missing auth config still makes Hermes fail
  # closed instead of serving an unauthenticated control plane.
  systemd.services.hermes-dashboard = {
    description = "Hermes Agent dashboard WebUI";
    after = [
      "hermes-agent.service"
      "hermes-secret-init.service"
    ];
    wants = [
      "hermes-agent.service"
      "hermes-secret-init.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HERMES_HOME = "${config.services.hermes-agent.stateDir}/.hermes";
      HOME = config.services.hermes-agent.stateDir;
      HERMES_DASHBOARD_PORT = toString hermesDashboardPort;
    };

    serviceConfig = {
      User = config.services.hermes-agent.user;
      Group = config.services.hermes-agent.group;
      WorkingDirectory = config.services.hermes-agent.workingDirectory;
      EnvironmentFile = hermesSecretEnv;
      ExecStart = "${lib.getExe config.services.hermes-agent.package} dashboard --host 0.0.0.0 --port ${toString hermesDashboardPort} --no-open --skip-build";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Tailnet-only dashboard ingress. Do not add this port to global
  # allowedTCPPorts: the dashboard is a control plane and must not be reachable
  # from the public internet or the VM tap edge.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ hermesDashboardPort ];

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

    # Seed the agent persona. Hermes builds its identity from
    # $HERMES_HOME/SOUL.md exclusively (agent/prompt_builder.py load_soul_md);
    # absent that file it seeds its stock "Hermes Agent by Nous Research"
    # default once and never overwrites an existing one. Mirror those
    # semantics with tmpfiles `C` (copy only if missing): the repo copy is the
    # immutable keel, the runtime copy is Vasyl's to grow — a rebuild must not
    # reset what the agent has tended. 0660 hermes:hermes matches what Hermes
    # itself creates under its managed-mode umask.
    tmpfiles.rules = [
      "C ${config.services.hermes-agent.stateDir}/.hermes/SOUL.md 0660 hermes hermes - ${./SOUL.md}"
      # Seed the manual secret file empty (`f` never overwrites) so it exists
      # with safe ownership before anyone edits it: hermes' own merge
      # tolerates absence, but pre-creating avoids a root:root 0644 footgun
      # from a casual `sudo vim`. (Tailscale needs no seed: tailscaled's unit
      # manages /var/lib/tailscale itself via StateDirectory, and auth is the
      # one-time interactive `tailscale up --ssh`.)
      "f ${hermesSecretEnv} 0600 hermes hermes - -"
    ];

    # Write-once generation of INTERNAL self-secrets — keys hermes alone
    # consumes, with no external issuer. Today that covers the HTTP API bearer
    # token, webhook signing secret, and dashboard basic-auth credentials:
    # appended to the secret file only if absent, never regenerated. External
    # credentials (Matrix) stay manual — see the README ("Secrets"). The hermes
    # module merges the secret file into $HERMES_HOME/.env at activation, so the
    # key is live from the first activation/boot after it is generated.
    services = {
      hermes-secret-init = {
        description = "Generate internal hermes-agent secrets (write-once)";
        before = [ "hermes-agent.service" ];
        path = [ pkgs.openssl ];
        serviceConfig.Type = "oneshot";
        script = ''
          grep -q '^API_SERVER_KEY=' ${hermesSecretEnv} ||
            echo "API_SERVER_KEY=$(openssl rand -hex 32)" >> ${hermesSecretEnv}
          grep -q '^WEBHOOK_SECRET=' ${hermesSecretEnv} ||
            echo "WEBHOOK_SECRET=$(openssl rand -hex 32)" >> ${hermesSecretEnv}
          grep -q '^HERMES_DASHBOARD_BASIC_AUTH_USERNAME=' ${hermesSecretEnv} ||
            echo "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=mykhailo" >> ${hermesSecretEnv}
          grep -q '^HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=' ${hermesSecretEnv} ||
            echo "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=$(openssl rand -base64 32)" >> ${hermesSecretEnv}
          grep -q '^HERMES_DASHBOARD_BASIC_AUTH_SECRET=' ${hermesSecretEnv} ||
            echo "HERMES_DASHBOARD_BASIC_AUTH_SECRET=$(openssl rand -hex 32)" >> ${hermesSecretEnv}
        '';
      };

      # Gate the agent on the generator: pulled in and ordered after it.
      hermes-agent = {
        wants = [ "hermes-secret-init.service" ];
        after = [ "hermes-secret-init.service" ];
        serviceConfig = {
          # The hermes module unconditionally puts the deprecated
          # MESSAGING_CWD into the unit env (settings.terminal.cwd above is
          # the canonical replacement, same value). Re-defining the env key
          # would conflict without mkForce, so strip it from the final
          # process env instead — UnsetEnvironment applies after
          # Environment= — and the gateway's startup deprecation warning
          # stays quiet.
          UnsetEnvironment = "MESSAGING_CWD";
          # Cover the gateway's 180s restart drain plus the 30s headroom its
          # startup check expects; the module leaves systemd's 90s default,
          # which would SIGKILL the gateway mid-drain.
          TimeoutStopSec = "210s";
          # The upstream module hardens with NoNewPrivileges = true, which
          # blocks setuid for the whole process tree — the agent's
          # passwordless sudo (security.sudo.extraRules below) would be dead
          # letter under it. ProtectSystem = "strict" must fall with it:
          # sudo'd children inherit the unit's mount namespace, so system
          # activation would still see a read-only /etc. mkForce because the
          # module sets plain values.
          NoNewPrivileges = lib.mkForce false;
          ProtectSystem = lib.mkForce false;
        };
      };

      nix-upper-gc = {
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

      # Hermes re-tightens $HERMES_HOME/.env to 0600 ~1s into startup: it
      # rewrites the file via tempfile.mkstemp (born 0600) + atomic replace
      # during config migration, and its _secure_file() only ever tightens and
      # no-ops in managed mode — so neither the activation relabel nor the
      # .hermes default ACL keeps .env group-readable (a 0600-created file
      # zeroes the inherited ACL mask). Re-assert 0660 hermes:hermes on every
      # change, so mykhailo (hermes group) keeps read access for `hermes chat`.
      # chmod/chown emit IN_ATTRIB, which PathChanged ignores — no self-trigger.
      hermes-env-perms = {
        path = [ pkgs.coreutils ];
        serviceConfig.Type = "oneshot";
        script = ''
          f=${config.services.hermes-agent.stateDir}/.hermes/.env
          [ -e "$f" ] || exit 0
          chown hermes:hermes "$f"
          chmod 0660 "$f"
        '';
      };
    };

    paths.hermes-env-perms = {
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = "${config.services.hermes-agent.stateDir}/.hermes/.env";
        Unit = "hermes-env-perms.service";
      };
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

  # Make HERMES_HOME genuinely shared between the hermes daemon and mykhailo —
  # both in the hermes group (see addToSystemPackages, groups.hermes, and
  # mykhailo's membership below). The module already gives the daemon UMask
  # 0007 and sets /var/lib/hermes + .hermes to 2770 (setgid), but two distinct
  # UIDs write here: the module's activation installs .env 0640 (group can't
  # write), readline creates .hermes_history 0600 on first use, and stale live
  # files predate the group-share intent — so `hermes chat` as mykhailo hits
  # EACCES on .env / .hermes_history. Fix in one place, ordered right after the
  # module's "hermes-agent-setup" (which rewrites .env every activation): a
  # default ACL makes NEW files group-rw regardless of the creator's umask, and
  # a recursive pass relabels the already-created tree (the fresh 0640 .env
  # included) to group-rw. Scoped to .hermes only — secret.env is a sibling at
  # 0600 and must stay unexposed.
  system.activationScripts.hermes-shared-perms = {
    deps = [ "hermes-agent-setup" ];
    text = ''
      home=${config.services.hermes-agent.stateDir}/.hermes
      if [ -d "$home" ]; then
        # readline opens history 0600 on create, locking out the other group
        # UID; pre-create it group-writable so both only ever append.
        [ -e "$home/.hermes_history" ] ||
          install -o hermes -g hermes -m 0660 /dev/null "$home/.hermes_history"
        ${pkgs.acl}/bin/setfacl -R -d -m g::rwX "$home"
        ${pkgs.acl}/bin/setfacl -R -m g::rwX "$home"
      fi
    '';
  };

  # The VM is the sandbox: the hermes user gets passwordless sudo (per
  # Mykhailo) so the agent can self-administer — activate built closures,
  # restart units, inspect the system — without a host round-trip. The
  # boundary stays the VM edge, not the uid.
  security.sudo = {
    wheelNeedsPassword = false;
    extraRules = [
      {
        users = [ "hermes" ];
        commands = [
          {
            command = "ALL";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];
  };

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
