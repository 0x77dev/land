{
  pkgs,
  lib,
  inputs,
  namespace,
  ...
}:
let
  muscle = lib.${namespace}.shared.builders.muscle;
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

    # Guest internet via NAT; no externalInterface needed (no port forwards),
    # so masquerading follows whatever uplink NetworkManager has up.
    nat = {
      enable = true;
      internalInterfaces = [ "vm-vasyl" ];
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

    # The nix-daemon authenticates to muscle via the YubiKey, exposed through
    # mykhailo's gpg-agent ssh socket (same as the Darwin hosts' launchd setup).
    # uid 1000 = first normal user (uids are auto-allocated, so not in eval).
    services.nix-daemon.environment.SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
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

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.containerd-snapshotter = true;
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
      # model pulled manually outside this list.
      loadModels = [
        "qwen3.6:35b-a3b-q8_0"
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
  # Spark for inference.
  nix = {
    distributedBuilds = true;
    buildMachines = muscle.mkMachines { sshUser = "mykhailo"; };
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
