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
    kernelModules = [ "kvm-amd" ];
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
      options = [ "discard" ];
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
    steam-hardware.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    alvr = {
      enable = true;
      openFirewall = true;
    };

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };

    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general.renice = 10;
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };
      };
    };

    appimage = {
      enable = true;
      binfmt = true;
    };

    chromium.enable = true;
    fish.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "mykhailo" ];
    };
  };

  services = {
    desktopManager.cosmic = {
      enable = true;
      xwayland.enable = true;
    };
    displayManager.cosmic-greeter.enable = true;

    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
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
    builders = {
      enable = true;
      maxJobs = 64;
      speedFactor = 4;
    };
  };

  services.time-client = {
    enable = true;
    ptp = {
      enable = true;
      interface = "eno1np0";
      timestamping = "software";
    };
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
      chromium
      pkgs.${namespace}.tx-02-variable
      gitFull
      vim
      iperf3
      steamtinkerlaunch
      protontricks
      yubikey-personalization
      yubikey-manager
      libfido2
      opensc
    ];

    variables.CUDA_PATH = "${pkgs.cudatoolkit}";
  };

  services.udev.packages = with pkgs; [
    yubikey-personalization
    xr-hardware
  ];

  networking.firewall.enable = false;

  nix = {
    buildMachines = lib.mkForce [ ];
    distributedBuilds = lib.mkForce false;
  };

  system.stateVersion = "25.05";
}
