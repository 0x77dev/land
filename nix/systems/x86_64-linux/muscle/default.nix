{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
{
  imports = [
    ./disko-config.nix
  ];

  networking = {
    hostName = "muscle";
    domain = "0x77.computer";
    useDHCP = lib.mkForce true;
  };

  boot = {
    supportedFilesystems = [
      "ntfs"
      "ext2"
    ];
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
      "video=DP-4:5120x1440@240"
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    consoleLogLevel = 3;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.overcommit_ratio" = 100;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 256 * 1024;
      discardPolicy = "once";
    }
  ];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    nvidia = {
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      nvidiaSettings = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
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

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features = {
        containerd-snapshotter = true;
      };
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  programs = {
    dconf.enable = true;

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
    };

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
    };

    gamemode.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
    };

    chromium = {
      enable = true;
      extensions = [
        # cspell:disable-next-line
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      ];
    };
    fish.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
    };

    # KDE Plasma 6 with Wayland
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      extraConfig.pipewire."context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
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

    time-client = {
      enable = true;
      ptp = {
        enable = true;
        interface = "eno1np0";
        timestamping = "software";
      };
    };

    tailscale.enable = true;
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  powerManagement.enable = false;

  modules = {
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
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "video"
      "audio"
      "kvm"
      "input"
    ];
    shell = pkgs.fish;
  };

  fonts.fontconfig.enable = true;

  environment = {
    systemPackages = with pkgs; [
      nvtopPackages.full
      cudatoolkit
      cudaPackages.libcufile
      cudaPackages.gdrcopy
      cudaPackages.nccl
      btop
      fastfetch
      hwloc
      google-chrome
      pkgs.${namespace}.tx-02-variable
      gitFull
      vim
      iperf3
      libfido2
      opensc
      ghostty
      adwaita-icon-theme
      dconf-editor
      wl-clipboard
      xdg-utils
      mangohud
      protonup-qt
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.kcalc
      kdePackages.spectacle
      kdePackages.gwenview
      kdePackages.konsole
      kdePackages.kate
    ];

    variables = {
      CUDA_PATH = "${pkgs.cudatoolkit}";
    };

    # Session variables for Wayland/Electron apps
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  networking.firewall.enable = false;

  nix = {
    buildMachines = lib.mkForce [ ];
    distributedBuilds = lib.mkForce false;
  };

  system.stateVersion = "25.11";
}
