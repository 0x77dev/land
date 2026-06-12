{
  pkgs,
  lib,
  inputs,
  namespace,
  ...
}:
let
  muscle = lib.${namespace}.shared.builders.muscle;

  # Voice stack for vasyl (see ../vasyl): both ends serve OpenAI-compatible
  # one-shot endpoints on the VM tap edge, next to Ollama.
  #
  # Kokoro-82M weights, declaratively pinned (Apache-2.0). URLs reference an
  # explicit HF revision rather than `main`, so upstream history moving can
  # never break the fixed-output hashes.
  kokoroRev = "f3ff3571791e39611d31c381e3a41a3af07b4987";
  kokoroConfig = pkgs.fetchurl {
    url = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/${kokoroRev}/config.json";
    hash = "sha256-WrsB4kA7ByvwPQT94WBEPiCdeg2tSaQjvhUZa5tDwX8=";
  };
  kokoroModel = pkgs.fetchurl {
    url = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/${kokoroRev}/kokoro-v1_0.pth";
    hash = "sha256-SW26EY0aWPXz2y78iNvcIW4Eg/yJ/m5H7h8sU/GK0eQ=";
  };
  # Default voice. Good alternates: am_fenrir, am_puck — fetch them the same
  # way and append to KOKORO_VOICES below to enable.
  kokoroVoiceMichael = pkgs.fetchurl {
    url = "https://huggingface.co/hexgrad/Kokoro-82M/resolve/${kokoroRev}/voices/am_michael.pt";
    hash = "sha256-mkQ7eaSyJImlsKt8ZRoLzRowvvZ1woMz8Glxq71HvTc=";
  };

  # kokoro pulls in torch, which this host builds with CUDA for sm_121 via
  # the global cudaSupport/cudaCapabilities (see the dgx-spark module). The
  # from-source torch build is huge — it rides the muscle build offload
  # enabled under `nix` below instead of the Grace cores.
  kokoroPython = pkgs.python3.withPackages (ps: [
    ps.kokoro
    ps.fastapi
    ps.uvicorn
    # misaki[en] G2P loads this spaCy model at KPipeline init; without it,
    # it spacy.cli.download()s at startup → crash-loop offline.
    ps.spacy-models.en_core_web_sm
  ]);

  parakeetShimPython = pkgs.python3.withPackages (ps: [
    ps.fastapi
    ps.httpx
    ps.python-multipart
    ps.uvicorn
  ]);
in
{
  networking = {
    hostName = "spark";
    domain = "osv.computer";
    # NetworkManager (GNOME's default) handles DHCP — networkd wouldn't lease here.
    networkmanager = {
      enable = true;
      # MicroVM taps belong to networkd below, not NetworkManager.
      unmanaged = [ "interface-name:vm-*" ];
    };
    firewall.enable = false;

    # Guest internet via NAT, masqueraded out the RJ45 uplink. Without
    # externalInterface the module still masquerades, but unscoped (no `-o`):
    # guest flows get SNATed out *every* egress path (tailscale0 included),
    # and with the firewall off the rules ride a standalone nat.service with
    # no ordering against docker's FORWARD-policy-DROP setup. Pinning the
    # uplink renders `-o enP7s7` on both the MASQUERADE and FORWARD-accept
    # rules. enP7s7 is the Spark's Realtek 10GbE port — a firmware-path
    # predictable name, stable on this hardware; reconfirm on the box with
    # `ip route get 1.1.1.1` if the uplink ever moves.
    nat = {
      enable = true;
      internalInterfaces = [ "vm-vasyl" ];
      externalInterface = "enP7s7";
    };
  };

  # vasyl — hermes-agent microVM (see nix/systems/aarch64-linux/vasyl).
  # Built from this flake's nixosConfigurations with the host: rebuilding
  # spark updates and restarts the VM (no imperative `microvm -u` step).
  microvm.vms.vasyl = {
    flake = inputs.self;
    restartIfChanged = true;
  };

  # Host side of the VM edge: 10.77.0.1 ↔ 10.77.0.2 (vasyl) on a dedicated
  # tap. The guest reaches Ollama at 10.77.0.1:11434 (it listens broadly).
  # networkd only manages this tap; NetworkManager keeps the uplinks.
  systemd.network = {
    enable = true;
    networks."40-vm-vasyl" = {
      matchConfig.Name = "vm-vasyl";
      address = [ "10.77.0.1/24" ];
    };
  };

  # Forwarding resolver for vasyl: an extra stub listener on the tap edge so
  # the guest inherits whatever upstream DNS spark currently uses (guest →
  # 10.77.0.1 → host upstreams) instead of hardcoding resolvers in the guest.
  # The stub freebinds, so it comes up before the tap exists; NetworkManager
  # integrates with resolved automatically once it is enabled. The host
  # firewall is off, so no port-53 opening is needed.
  services.resolved = {
    enable = true;
    settings.Resolve.DNSStubListenerExtra = "10.77.0.1";

    # Empty fallback: vasyl inherits spark's upstreams via the stub above, so if
    # spark ever has no upstream, resolution must fail loudly here instead of
    # silently leaking to systemd's compiled-in public resolvers.
    settings.Resolve.FallbackDNS = [ ];
  };

  systemd = {
    # Always-on appliance — never suspend/hibernate (it serves Ollama/compute).
    sleep.settings.Sleep = {
      AllowSuspend = "no";
      AllowHibernation = "no";
      AllowSuspendThenHibernate = "no";
      AllowHybridSleep = "no";
    };

    services = {
      # The nix-daemon authenticates to muscle via the YubiKey, exposed through
      # mykhailo's gpg-agent ssh socket (same as the Darwin hosts' launchd setup).
      # uid 1000 = first normal user (uids are auto-allocated, so not in eval).
      nix-daemon.environment.SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";

      # TTS for vasyl: Kokoro-82M on CUDA, pure Nix — torch from this host's
      # cudaSupport package set plus the pinned weights above, no container.
      # (The stock ghcr.io/remsky/kokoro-fastapi-gpu arm64 image is broken on
      # sm_121; if this from-source path ever becomes untenable, a self-built
      # CUDA container would be the fallback.) The ~60-line shim serves
      # OpenAI-compatible /v1/audio/speech.
      kokoro-openai = {
        description = "Kokoro-82M TTS (OpenAI-compatible) for vasyl";
        wantedBy = [ "multi-user.target" ];
        # Binds the tap edge; if 10.77.0.1 isn't up yet the bind fails and the
        # restart loop converges once networkd has the address.
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.ffmpeg ];
        environment = {
          # Weights are pinned in the store — never touch the hub.
          HF_HUB_OFFLINE = "1";
          KOKORO_CONFIG = "${kokoroConfig}";
          KOKORO_MODEL = "${kokoroModel}";
          KOKORO_VOICES = "am_michael=${kokoroVoiceMichael}";
          KOKORO_HOST = "10.77.0.1";
          KOKORO_PORT = "8101";
          # Writable HOME for the CUDA/torch JIT caches under DynamicUser.
          HOME = "/var/cache/kokoro-openai";
        };
        serviceConfig = {
          ExecStart = "${kokoroPython}/bin/python ${./kokoro-shim.py}";
          DynamicUser = true;
          SupplementaryGroups = [
            "render"
            "video"
          ];
          CacheDirectory = "kokoro-openai";
          Restart = "on-failure";
          RestartSec = 5;
        };
      };

      # STT for vasyl: an OpenAI-compatible facade in front of NVIDIA's
      # Parakeet NIM. The raw NIM endpoint selects the DGX Spark profile by
      # BCP-47 language and rejects arbitrary OpenAI `model` names; the shim
      # accepts the normal OpenAI multipart shape from Hermes, ignores `model`,
      # supplies `language=en-US`, and returns `{ "text": ... }`.
      parakeet-openai = {
        description = "Parakeet NIM STT (OpenAI-compatible) for vasyl";
        wantedBy = [ "multi-user.target" ];
        wants = [
          "network-online.target"
          "docker-parakeet-nim.service"
        ];
        after = [
          "network-online.target"
          "docker-parakeet-nim.service"
        ];
        environment = {
          PARAKEET_HOST = "10.77.0.1";
          PARAKEET_PORT = "8102";
          PARAKEET_LANGUAGE = "en-US";
          PARAKEET_UPSTREAM_URL = "http://127.0.0.1:9000/v1/audio/transcriptions";
          PARAKEET_TIMEOUT_SECONDS = "300";
        };
        serviceConfig = {
          ExecStart = "${parakeetShimPython}/bin/python ${./parakeet-openai-shim.py}";
          DynamicUser = true;
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };

    # NGC secrets for the parakeet-nim container, seeded empty (`f` never
    # overwrites) and filled by hand — see the README ("Secrets"). The model
    # cache is bind-mounted into the container, whose unprivileged inner uid
    # must be able to write it (NVIDIA's own quickstart opens it the same way).
    tmpfiles.rules = [
      "d /var/lib/nim 0700 root root - -"
      "f /var/lib/nim/ngc-key 0600 root root - -"
      "f /var/lib/nim/ngc.env 0600 root root - -"
      "d /var/lib/nim/cache 0777 root root - -"
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.max_map_count" = 2147483642;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  # NVIDIA DGX Spark (GB10) hardware profile: CUDA, NVIDIA driver + container
  # toolkit, fwupd, the Flox CUDA cache, and the full-NVMe XFS disko layout.
  hardware.dgx-spark.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  virtualisation = {
    docker = {
      enable = true;
      daemon.settings.features.containerd-snapshotter = true;
    };

    # STT for vasyl: Parakeet 1.1B RNNT Multilingual as an NVIDIA NIM — the
    # one justified container here (NVIDIA ships it CUDA-ready for Blackwell
    # and the DGX Spark per the speech NIM support matrix; it is the only
    # Spark-supported Parakeet). The raw NIM HTTP API is kept loopback-only;
    # vasyl reaches it through the OpenAI-compatible parakeet-openai shim on
    # the tap edge. GPU access is CDI:
    # hardware.nvidia-container-toolkit (dgx-spark module) generates the spec
    # and docker >= 28.2 has CDI on by default, so `--device=nvidia.com/gpu`
    # is the official path (no --runtime=nvidia wrapper on NixOS).
    oci-containers = {
      backend = "docker";
      containers.parakeet-nim = {
        # Tag and profile are from the NIM ASR support matrix; reconfirm both
        # against the NGC model card at deploy time.
        image = "nvcr.io/nim/nvidia/parakeet-1-1b-rnnt-multilingual:latest";
        # NGC registry auth: literal "$oauthtoken" username + the API key.
        # The key file is seeded empty below; the unit retries until filled
        # (same manual-fill discipline as vasyl's secret files — see the
        # README, "Secrets").
        login = {
          registry = "nvcr.io";
          username = "$oauthtoken";
          passwordFile = "/var/lib/nim/ngc-key";
        };
        # NGC_API_KEY=<key>, the in-container model-download credential.
        environmentFiles = [ "/var/lib/nim/ngc.env" ];
        environment = {
          NIM_HTTP_API_PORT = "9000";
          NIM_GRPC_API_PORT = "50051";
          # The documented offline (one-shot) profile for this container —
          # it ships no diarizer-disabled profiles, only sortformer+silero.
          NIM_TAGS_SELECTOR = "diarizer=sortformer,mode=ofl,type=default,vad=silero";
        };
        ports = [ "127.0.0.1:9000:9000" ];
        volumes = [ "/var/lib/nim/cache:/opt/nim/.cache" ];
        extraOptions = [
          "--device=nvidia.com/gpu=all"
          "--shm-size=8g"
        ];
      };
    };
  };

  programs = {
    dconf.enable = true;
    nix-ld.enable = true;
    fish.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };

    # Full GNOME on Wayland (gdm defaults to Wayland).
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
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

    pcscd.enable = true;
    tailscale.enable = true;

    # Ollama with CUDA on the GB10 GPU. Listens on all interfaces (the host
    # firewall is disabled and it's reachable over Tailscale).
    ollama = {
      enable = true;
      # Root-cause fix for qwen3.6 tool-call drift → HTTP 500 (ollama/ollama#16383):
      # carry the unmerged parser fix (ollama/ollama#16398, 2 commits) as source
      # patches. Spark-only — other hosts keep the stock pkgs.ollama-cuda. Pure Go
      # parser change + tests; no go.mod/go.sum impact, so vendorHash is untouched.
      # Drop once the pinned channel's ollama contains the merged fix (the build
      # fails loudly at patchPhase if upstream code drifts).
      package = pkgs.ollama-cuda.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            name = "ollama-qwen36-tolerate-tool-template-drift.patch";
            url = "https://github.com/ollama/ollama/commit/beed6703d8fe3795049db45863458785774ef396.patch";
            hash = "sha256-xh59I8WNHjkH2Rx1jsGl+8anjvGA/294yz5Z3dV87QY=";
          })
          (pkgs.fetchpatch {
            name = "ollama-qwen36-skip-empty-tool-call-envelopes.patch";
            url = "https://github.com/ollama/ollama/commit/769dcb5eb7bc8707aabf5de611a1dcb05ffa3ab5.patch";
            hash = "sha256-kRSPiX+wJfv7HOKhaxP50ZHUdPIOhXbjdKp/0L8AYOU=";
          })
        ];
      });
      host = "0.0.0.0";

      # Models for vasyl's hermes-agent (see ../vasyl): pulled by the
      # non-blocking ollama-model-loader.service, content-addressed (no-op
      # when unchanged). syncModels stays off on purpose — it would GC any
      # model pulled manually outside this list. The primary is Q4_K_M
      # (~24 GB on disk, down from the old q8_0's ~39 GB) — ample headroom in
      # the GB10's 128 GiB unified memory beside vasyl's 32 GiB and the KV
      # cache. Same 35B-A3B arch, so the qwen3.6 tool-parser patch still applies.
      loadModels = [
        "huihui_ai/Qwen3.6-abliterated:35b-Claude-4.7"
        "gpt-oss:20b"
      ];

      environmentVariables = {
        # Hermes hard-requires >=64K; vasyl's context_length must match.
        OLLAMA_CONTEXT_LENGTH = "131072";
        # Off by default; prerequisite for KV-cache quantization below,
        # which halves KV memory (~2.7 → ~1.35 GB at 128K).
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # Agent box: don't evict the models after the 5m default.
        OLLAMA_KEEP_ALIVE = "24h";
        # KV is allocated per parallel slot — keep a single slot.
        OLLAMA_NUM_PARALLEL = "1";
      };
    };
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  # Always-on appliance — sleep is inhibited in the `systemd` block above.
  powerManagement.enable = false;

  modules = {
    vscode-server.enable = true;
    observability.enable = true;
    security-tools.enable = true;
  };

  # Offload large/parallel builds to muscle (Threadripper 7985WX) — it
  # out-compiles the Grace cores even on aarch64 via binfmt, and frees the
  # Spark for inference. The kokoro stack's from-source torch-CUDA build is
  # exactly the job this exists for.
  #
  # The nix-daemon runs as root, so it authenticates to muscle with a
  # dedicated root-readable key (one-time: generate /root/.ssh/id_ed25519 on
  # spark, append its pubkey to mykhailo@muscle's authorized_keys — same
  # manual-key discipline as the NGC/Matrix secrets). A passwordless key is
  # what makes the offload work unattended (e.g. nightly autoUpgrade), where
  # the YubiKey-backed agent below is unavailable.
  nix = {
    distributedBuilds = true;
    buildMachines = muscle.mkMachines {
      sshUser = "mykhailo";
      sshKey = "/root/.ssh/id_ed25519";
    };
  };
  programs.ssh.knownHosts.muscle = muscle.knownHost;

  # Nightly unattended upgrade: spark pulls the public land flake from GitHub and
  # rebuilds itself (the 26.05 module adds `--refresh --flake` on its own). vasyl
  # rides along — its `flake = self` attachment re-links and restarts the guest
  # on switch, so no guest-side upgrade machinery is needed. allowReboot is on
  # per Mykhailo: kernel/bootloader updates apply unattended, a brief Ollama
  # interruption is accepted, and vasyl picks up new kernels on its restart
  # regardless. Daily GC is already inherited from the shared nix-config.
  system.autoUpgrade = {
    enable = true;
    flake = "github:0x77dev/land";
    flags = [ "--print-build-logs" ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = true;
  };

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "wheel"
      "docker"
      "video"
      "audio"
      "input"
      "render"
    ];
    shell = pkgs.fish;
  };

  fonts.fontconfig.enable = true;

  environment = {
    systemPackages = with pkgs; [
      # System monitoring
      btop
      fastfetch
      hwloc

      # CUDA
      cudatoolkit
      cudaPackages.nccl

      # Desktop apps
      pkgs.${namespace}.tx-02-variable
      gitFull
      vim
      iperf3
      libfido2
      opensc
      ghostty
      wl-clipboard
      xdg-utils

      gnome-tweaks
    ];

    variables.CUDA_PATH = "${pkgs.cudatoolkit}";

    # Wayland for Electron/Chromium apps
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  system.stateVersion = "25.11";
}
