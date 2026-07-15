{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
{
  imports = [
    ./fde.nix
  ];

  networking = {
    hostName = "muscle";
    domain = "osv.computer";
    useDHCP = lib.mkForce true;
  };

  boot = {
    supportedFilesystems = [
      "ntfs"
      "ext2"
    ];
    # Load NVIDIA modules early for better KMS
    initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    # CachyOS kernel optimized for AMD Zen 4 (Threadripper 7985WX)
    # - LTO: Link-time optimization for better performance
    # - Zen 4: Architecture-specific optimizations for Threadripper
    # - EEVDF: Balanced scheduler for both AI and gaming workloads
    # https://github.com/xddxdd/nix-cachyos-kernel
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-zen4;
    kernelParams = [
      "video=DP-5:5120x1440@240"
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
      # Let Linux reassign PCI bridge windows when firmware leaves resources unassigned.
      "pci=realloc"
      # Some games need split lock detection disabled
      "split_lock_detect=off"
      "amd-pstate=active"
      # Run IRQ handlers as threads so rtkit-boosted audio threads can
      # preempt them — near-RT audio without a PREEMPT_RT kernel.
      "threadirqs"
      # GPUDirect Storage: NVIDIA requires the IOMMU off or in passthrough
      # for peer-to-peer DMA between NVMe and GPU; pt keeps VFIO isolation.
      "iommu=pt"
    ];
    consoleLogLevel = 3;
    loader = {
      # lanzaboote replaces systemd-boot and signs everything it installs
      # with the sbctl keys in /var/lib/sbctl (created once with
      # `sbctl create-keys`, enrolled with `sbctl enroll-keys --microsoft`).
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    kernel.sysctl = {
      # Memory management
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.overcommit_ratio" = 100;
      "vm.max_map_count" = 2147483642;
      # le9uo: prevent page thrashing under memory pressure
      "vm.anon_min_ratio" = 15;
      "vm.clean_min_ratio" = 15;
      # NUMA balancing for 32-core Threadripper
      "kernel.numa_balancing" = 1;
      # Network: BBR congestion control
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
    # Expose arm64 Linux builds to Darwin clients through NixOS binfmt support.
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    infiniband.enable = true;
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    cpu.amd.updateMicrocode = true;
    nvidia = {
      open = true;
      # Kernel-module driver must match the running kernel's ABI, so it is
      # pulled from `boot.kernelPackages` (the CachyOS kernel) rather than the
      # unstable overlay. Only NVIDIA userspace (CUDA, nvtop, container
      # toolkit) is routed from unstable.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      # Keeps GPU state initialized; required for fast GPUDirect Storage
      # (P2PDMA) driver bring-up.
      nvidiaPersistenced = true;
    };
    nvidia-container-toolkit.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
  };

  # Docker 29 uses the containerd image store by default.
  virtualisation.docker.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    # Latest CUDA package set nixpkgs ships (default is 12.9).
    cudaVersion = "13.3";
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  programs = {
    dconf = {
      enable = true;
      # The Samsung G95SC misreports HDR luminance, so pin its reference to
      # 400 nits (True Black 400). The ASUS XG32UCDS carries accurate EDID
      # luminance data (factory calibrated, ~1000 nits peak) — no override,
      # or highlights get capped.
      profiles =
        let
          output-luminance = [
            (lib.gvariant.mkTuple [
              "DP-5"
              "SAM"
              "Odyssey G95SC"
              "H1AK500000"
              (lib.gvariant.mkUint32 1)
              400.0
            ])
          ];
          mutter-settings."org/gnome/mutter" = {
            inherit output-luminance;
          };
        in
        {
          # Shell extensions are enabled by home-manager (modules.home.gnome).
          user.databases = [ { settings = mutter-settings; } ];
          gdm.databases = [ { settings = mutter-settings; } ];
        };
    };

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };

    nix-ld.enable = true;

    # uinput typing daemon: voxtype's output fallback on GNOME, where the
    # wtype virtual-keyboard protocol isn't available.
    ydotool.enable = true;

    appimage = {
      enable = true;
      binfmt = true;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      # Add libraries needed for gamescope within Steam
      # https://wiki.nixos.org/wiki/Steam#Gamescope_fails_to_launch_when_used_within_Steam
      package = pkgs.steam.override {
        extraPkgs =
          pkgs': with pkgs'; [
            libxcursor
            libxi
            libxinerama
            libxscrnsaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
          ];
      };
    };

    # GameMode: CPU governor, I/O priority optimizations
    # Use with: gamemoderun %command% in Steam launch options
    # https://wiki.nixos.org/wiki/GameMode
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
          softrealtime = "auto";
          inhibit_screensaver = 0; # GNOME handles this
        };
        # GPU clock offsets via nvidia-settings don't work on Wayland
        # NVIDIA driver handles boost clocks automatically
        gpu = {
          apply_gpu_optimisations = "off";
        };
      };
    };

    # Gamescope: Steam Deck-like compositor for games
    # https://wiki.nixos.org/wiki/Steam#Gamescope_Compositor_/_Boot_to_Steam_Deck
    gamescope = {
      enable = true;
      capSysNice = true;
      # Samsung Odyssey G95SC: 5120x1440 @ 239.999Hz (reported as 239)
      args = [
        "-W 5120"
        "-H 1440"
        "-r 239"
        "-f" # fullscreen
        "--adaptive-sync"
        "--hdr-enabled"
        "--mangoapp"
      ];
    };

    # Policy source for Helium (no Chromium browser installed): the helium
    # module reuses /etc/chromium policies and native-messaging hosts, so
    # extensions declared here are force-installed into Helium.
    chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
        "kcmipingpfbohfjckomimmahknoddnke" # Vicinae Integration
      ];
    };

    # Native-messaging host for the Vicinae browser extension (Helium reads
    # /etc/chromium). https://docs.vicinae.com/browser-extension
    helium.vicinaePackage = pkgs.${namespace}.vicinae;
    fish.enable = true;

    # GNOME's lightweight mail client (Superhuman stays the mailto default).
    geary.enable = true;
  };

  services = {
    # GNOME and the Bluetooth Battery Meter consume peripheral batteries from
    # UPower, including Logitech HID++ devices exposed by the kernel driver.
    upower.enable = lib.mkForce true;

    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
    };
    # I/O scheduler for NVMe (none is best for high-performance NVMe)
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    '';

    # Full GNOME on Wayland (gdm defaults to Wayland).
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    # Pro-audio grade PipeWire: 48kHz clock with a wide dynamic quantum
    # (64-2048) so pro apps get ~1.3ms latency while desktop streams coalesce
    # into efficient large buffers, and the highest-quality resampler for
    # anything not running at the native rate.
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig = {
        pipewire."10-clock"."context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [
            44100
            48000
            88200
            96000
            192000
          ];
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 64;
          "default.clock.max-quantum" = 2048;
        };
        client."10-resample"."stream.properties"."resample.quality" = 10;
        pipewire-pulse."10-resample"."stream.properties"."resample.quality" = 10;
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

    pcscd.enable = true;

    # Hardened printing: CUPS bound to localhost only, no shared queues, no
    # network browsing/discovery, web interface off. This also makes the
    # GNOME Settings printing panel unlockable (it needs cups running).
    printing = {
      enable = true;
      startWhenNeeded = true;
      listenAddresses = [ "localhost:631" ];
      browsing = false;
      browsed.enable = false; # no network printer discovery daemon
      defaultShared = false;
      webInterface = false;
      openFirewall = false;
    };

    # USB4/Thunderbolt device authorization (CalDigit TS5+ dock). GNOME's
    # Thunderbolt settings panel talks to bolt; enroll the dock once and its
    # accessories (USB, network, audio) connect automatically after that.
    hardware.bolt.enable = true;

    # Firmware updates via LVFS. Only the signed stable remote is used;
    # disable Passim P2P metadata sharing to keep the update path
    # vendor -> LVFS -> this host only.
    fwupd = {
      enable = true;
      daemonSettings.P2pPolicy = "nothing";
    };

    time-client = {
      enable = true;
      ptp = {
        enable = true;
        interface = "eno1np0";
        timestamping = "software";
      };
    };

    # Operator lets the quick-settings extension toggle Tailscale without sudo.
    tailscale = {
      enable = true;
      extraSetFlags = [ "--operator=mykhailo" ];
    };

    # LAN Ollama peer to Spark. Muscle has 2x RTX 6000 Ada GPUs (48 GB each),
    # so the pull set stays shared and vetted against that smaller VRAM budget.
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      loadModels = lib.${namespace}.shared.ollama.agentModels;

      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "131072";
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        OLLAMA_KEEP_ALIVE = "24h";
        OLLAMA_NUM_PARALLEL = "1";
      };
    };
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;

    # TPM 2.0 userspace: PKCS#11, TCTI env, and the tss group. Used by
    # systemd-cryptenroll for LUKS auto-unlock once the disk is encrypted.
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };

    # Realtime scheduling and locked memory for audio work (JACK/pro-audio
    # clients); rtkit handles PipeWire itself.
    pam.loginLimits = [
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "95";
      }
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }
    ];
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowSuspendThenHibernate = "no";
    AllowHybridSleep = "no";
  };

  # Belt and suspenders: mask every sleep target and make logind ignore all
  # sleep/power/lid requests. Locking or powering off the displays must not
  # stop user processes or their systemd user manager. GNOME independently
  # has idle-delay=0 and every inactive-sleep action set to "nothing".
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
    suspend-then-hibernate.enable = false;
  };
  services.logind.settings.Login = {
    IdleAction = "ignore";
    KillUserProcesses = false;
    UserStopDelaySec = "infinity";
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  powerManagement.enable = false;

  modules = {
    cachix-deploy = {
      enable = true;
      agentName = "muscle";
    };
    elgato-light-control.enable = true;
    yubikey-pam.enable = true;
    vr.enable = true;
    vscode-server.enable = true;
    observability.enable = true;
    security-tools.enable = true;
  };

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    # Keep user services alive independently of the graphical login session.
    linger = true;
    # Fresh key-only installs need an unlocked shadow entry or sshd rejects
    # even valid authorized keys. Password SSH is disabled independently;
    # set a local password with `passwd` after the first key login.
    initialHashedPassword = "";
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "video"
      "audio"
      "kvm"
      "ydotool" # voxtype typing fallback on GNOME
      "tss" # TPM 2.0 access via the TCTI environment
      "gamemode" # Required for GameMode CPU governor changes
    ];
    shell = pkgs.fish;
  };

  fonts.fontconfig = {
    enable = true;
    # QD-OLED panels use a triangular subpixel layout, so classic RGB
    # subpixel AA fringes. Grayscale smoothing avoids color fringing on both
    # this geometry and the rotated secondary display.
    antialias = true;
    hinting.style = "slight";
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
    # NixOS' aliases load after per-user Fontconfig files. Mirror the Home
    # presentation roles here so DejaVu/Noto system defaults cannot win.
    defaultFonts = {
      sansSerif = [
        "SF Pro Text"
        "Symbols Nerd Font"
      ];
      serif = [
        "New York Small"
        "Symbols Nerd Font"
      ];
      monospace = [
        "TX-02-Variable"
        "SF Mono"
        "Symbols Nerd Font Mono"
      ];
      emoji = [
        "Apple Color Emoji"
        "Noto Color Emoji"
      ];
    };
  };

  # GPUDirect Storage (cuFile): the modern NVMe P2PDMA path — upstream NVMe
  # driver + CONFIG_PCI_P2PDMA (already =y in the CachyOS kernel), no
  # nvidia-fs.ko or MOFED needed. True GDS needs O_DIRECT on ext4/XFS with
  # no dm-crypt in the path; everything else transparently falls back to
  # compat (bounce-buffer) mode.
  environment.etc."cufile.json".text = builtins.toJSON {
    properties = {
      allow_compat_mode = true;
      use_pci_p2pdma = true;
    };
    fs.generic.posix_unaligned_writes = false;
  };

  environment = {
    gnome.excludePackages = with pkgs; [
      yelp
      epiphany # Helium is the default browser
    ];

    systemPackages = with pkgs; [
      # System monitoring
      nvtopPackages.full
      btop
      fastfetch
      hwloc
      libgtop
      pciutils

      # CUDA
      cudatoolkit
      cudaPackages.libcufile
      cudaPackages.gdrcopy
      cudaPackages.nccl

      # Gaming - HDR support for gamescope
      # https://wiki.nixos.org/wiki/Steam#Gamescope_HDR
      gamescope-wsi

      # Gaming - Performance overlay (use with mangohud %command%)
      mangohud

      # Desktop apps
      gitFull
      vim
      iperf3
      libfido2
      opensc
      ghostty
      wl-clipboard
      xdg-utils
      dconf-editor

      # Secure Boot key management (lanzaboote signs with /var/lib/sbctl)
      sbctl

      # GNOME extras
      gnome-tweaks
      gnome-extension-manager
      gnomeExtensions.appindicator
      gnomeExtensions.astra-monitor
      gnomeExtensions.tailscale-qs
    ];

    variables = {
      CUDA_PATH = "${pkgs.cudatoolkit}";
      GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
    };
  };

  networking.firewall.enable = false;

  # Set Helium as default browser (system-wide)
  xdg.mime.defaultApplications = {
    "text/html" = "helium.desktop";
    "x-scheme-handler/http" = "helium.desktop";
    "x-scheme-handler/https" = "helium.desktop";
    "x-scheme-handler/about" = "helium.desktop";
    "x-scheme-handler/unknown" = "helium.desktop";
  };

  nix = {
    buildMachines = lib.mkForce [ ];
    distributedBuilds = lib.mkForce false;
    settings = {
      system-features = [
        "benchmark"
        "big-parallel"
        "kvm"
        "nixos-test"
      ];
    };
  };

  system.stateVersion = "25.11";
}
