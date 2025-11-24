{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./disko-config.nix
  ];

  # Hostname and networking
  networking = {
    hostName = "muscle";
    domain = "0x77.computer";
    useDHCP = true;
  };

  # Boot configuration
  boot = {
    kernelModules = [
      "kvm-amd"
      "nvidia-fs" # GPUDirect Storage
    ];
    extraModulePackages = with config.boot.kernelPackages; [
      pkgs.cudaPackages.nvidia_fs
    ];
    kernelParams = [
      "pcie_acs_override=downstream,multifunction" # Optimize PCIe for GDS
    ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # NVMe optimizations
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
    };
  };

  # Hardware configuration
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    # NVIDIA Configuration (Open-source drivers for RTX 6000 Ada)
    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = true;
      modesetting.enable = true;
      powerManagement.enable = false; # Disable power management for workstation
    };
    # Enable NVIDIA Container Toolkit for Docker/Podman
    nvidia-container-toolkit.enable = true;
    # GPU and graphics
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    # Bluetooth support (integrates with KDE via bluedevil)
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true; # Enable experimental features for better device support
        };
      };
    };
    # Steam hardware support (controllers, VR, etc)
    steam-hardware.enable = true;
  };

  # Virtualisation
  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };

  # Allow unfree packages (needed for NVIDIA drivers)
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # Programs configuration
  programs = {
    # ALVR for VR
    alvr = {
      enable = true;
      openFirewall = true;
    };
    # Gaming - Steam with full optimization (NixOS Wiki best practices)
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports for local transfers
      gamescopeSession.enable = true; # Enable GameScope session for better gaming performance
      extraCompatPackages = with pkgs; [
        proton-ge-bin # GE-Proton for better game compatibility
      ];
    };
    # GameMode for automatic performance optimizations when gaming
    gamemode = {
      enable = true;
      enableRenice = true; # Automatically renice games
      settings = {
        general = {
          renice = 10; # Priority boost for games
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };
    # AppImage support
    appimage = {
      enable = true;
      binfmt = true;
    };
    # Chromium browser integration with KDE Plasma
    chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;
    };
    # Fish shell
    fish.enable = true;

    # 1Password GUI with system integration
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "mykhailo" ];
    };
  };

  # VR Environment Variables
  systemd.user.services.monado.environment = {
    STEAMVR_LH_ENABLE = "1";
    XRT_COMPOSITOR_COMPUTE = "1";
    WMR_HANDTRACKING = "0";
    # Enable debugging if needed
    XRT_DEBUG_GUI = "0";

    # Force X11 instead of Wayland for NVIDIA compatibility
    XRT_COMPOSITOR_FORCE_NVIDIA = "1";
    SDL_VIDEODRIVER = "x11";
    # Ensure we don't see Wayland
    WAYLAND_DISPLAY = "";
    # Force Vulkan to use NVIDIA
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    # NVIDIA Vulkan hints
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };

  # Services configuration
  services = {
    # VR Configuration - Monado OpenXR runtime
    monado = {
      enable = true;
      defaultRuntime = true; # Register as default OpenXR runtime
      package =
        with pkgs;
        monado.overrideAttrs (
          _finalAttrs: _previousAttrs: {
            src = fetchFromGitLab {
              domain = "gitlab.freedesktop.org";
              owner = "thaytan";
              repo = "monado";
              rev = "dev-constellation-controller-tracking";
              hash = "sha256-x/X4HyyHdQUxn3CdMbWj5cfLvV7UyQe1D01H93UCk+M=";
            };
            patches = [ ];
          }
        );
    };
    # KDE Plasma 6 Desktop Environment with full ecosystem (2025 best practices)
    desktopManager.plasma6 = {
      enable = true;
      enableQt5Integration = true; # Enable Qt5 theming for broader app support
    };
    # SDDM Display Manager
    displayManager.sddm = {
      enable = true;
      wayland.enable = true; # Wayland is default and recommended for Plasma 6
      # Enable debug logging to diagnose login issues
      settings = {
        General = {
          DisplayServer = "wayland";
        };
      };
    };
    # X11 and input
    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
    };
    # Color management (integrates with KDE via colord-kde)
    colord.enable = true;
    # PipeWire audio (2025 standard)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      # Low latency configuration
      extraConfig.pipewire = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 512;
        };
      };
    };
    # OpenSSH
    openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        AllowAgentForwarding = true;
      };
    };
    # Yubikey support - PC/SC Smart Card Daemon
    # Enables Yubikey for FIDO2, U2F, OTP, PIV, and OpenPGP operations
    # NOTE: Does not affect existing SSH or GPG configurations
    pcscd.enable = true;
  };

  # XDG Portal support for proper Wayland integration
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
    ];
    config.common.default = "kde";
  };

  # Ensure proper session management
  services.displayManager.defaultSession = "plasma";

  # Security configuration
  security = {
    # KWallet PAM integration for automatic unlocking
    pam.services = {
      sddm.kwallet.enable = true;
      login.kwallet.enable = true;
    };
    # Real-time audio
    rtkit.enable = true;
    # Sudo without password
    sudo.wheelNeedsPassword = false;
  };

  # Never sleep/suspend/hibernate - workstation stays active 24/7
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # Disable all power management features
  powerManagement = {
    enable = false;
    powertop.enable = false;
  };

  # Distributed builds configuration
  modules.builders = {
    enable = true;
    maxJobs = 64; # Half of 128 cores
    speedFactor = 4; # Threadripper PRO is very fast
  };

  # User configuration
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
      "networkmanager"
      "video"
      "audio"
    ];
    shell = pkgs.fish;
  };

  # System packages for workstation
  environment.systemPackages = with pkgs; [
    # NVIDIA utilities
    nvtopPackages.full
    cudatoolkit

    # VR tools
    wlx-overlay-s

    # System monitoring
    btop
    fastfetch

    # Development tools
    git
    vim

    # Network tools
    iperf3

    # Web browsers
    chromium

    # Gaming utilities
    mangohud # Overlay for monitoring FPS, temps, etc in games
    gamemode # Optimizations for gaming
    gamescope # Micro-compositor for better gaming on Wayland
    steamtinkerlaunch # Advanced Steam launcher with many tweaks
    protontricks # Tool to run Winetricks commands for Proton games

    # Yubikey utilities
    yubikey-personalization # CLI tools for configuring YubiKey
    yubikey-manager # YubiKey Manager CLI and GUI
    libfido2 # Support for FIDO2/WebAuthn
    opensc # Smart card library and applications

    # KDE utilities (additional, beyond defaults)
    kdePackages.kcalc
    kdePackages.kcolorchooser
    kdePackages.kruler
    kdePackages.kdenlive
    kdePackages.krdc # Remote desktop client
    kdePackages.krfb # Remote desktop server
    kdePackages.kwalletmanager # KWallet management tool
    kdePackages.filelight # Disk usage visualization
  ];

  # Yubikey udev rules for proper device access
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # CUDA support
  environment.variables = {
    CUDA_PATH = "${pkgs.cudatoolkit}";
  };

  networking.firewall.enable = false;

  system.stateVersion = "25.05";
}
