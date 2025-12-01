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

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "ghostty";
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
    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
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

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany
    geary
    gnome-music
    totem
    gnome-photos
    gnome-connections
  ];

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
      yubikey-personalization
      yubikey-manager
      libfido2
      opensc
      ghostty
      gnome.gnome-tweaks
      gnome-extension-manager
      gnomeExtensions.dash-to-panel
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
    ];

    variables.CUDA_PATH = "${pkgs.cudatoolkit}";
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];

  networking.firewall.enable = false;

  nix = {
    buildMachines = lib.mkForce [ ];
    distributedBuilds = lib.mkForce false;
  };

  system.stateVersion = "25.05";
}
