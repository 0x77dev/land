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

  console = {
    earlySetup = true;
    font = "ter-v32n";
    packages = with pkgs; [ terminus_font ];
    colors = [
      "002b36"
      "dc322f"
      "859900"
      "b58900"
      "268bd2"
      "d33682"
      "2aa198"
      "eee8d5"
      "002b36"
      "cb4b16"
      "586e75"
      "657b83"
      "839496"
      "6c71c4"
      "93a1a1"
      "fdf6e3"
    ];
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

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  programs = {
    dconf = {
      enable = true;
      profiles = {
        user.databases = [
          {
            settings."org/gnome/mutter".output-luminance = [
              (lib.gvariant.mkTuple [
                "DP-4"
                "SAM"
                "Odyssey G95SC"
                "H1AK500000"
                (lib.gvariant.mkUint32 1)
                400.0
              ])
            ];
          }
        ];
        gdm.databases = [
          {
            settings."org/gnome/mutter".output-luminance = [
              (lib.gvariant.mkTuple [
                "DP-4"
                "SAM"
                "Odyssey G95SC"
                "H1AK500000"
                (lib.gvariant.mkUint32 1)
                400.0
              ])
            ];
          }
        ];
      };
    };

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

    chromium.enable = true;
    fish.enable = true;

    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "mykhailo" ];
    };
  };

  services = {
    kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        {
          name = "Terminus";
          package = pkgs.terminus_font;
        }
      ];
      extraConfig = ''
        font-size=18
        xkb-layout=us
      '';
    };

    xserver = {
      enable = true;
      xkb.layout = "us";
      videoDrivers = [ "nvidia" ];
      desktopManager.gnome.enable = true;
      displayManager.gdm.enable = true;
    };

    gnome = {
      core-os-services.enable = true;
      core-shell.enable = true;
      core-apps.enable = true;
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
  };

  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${pkgs.writeText "gdm-monitors.xml" ''
      <monitors version="2">
        <configuration>
          <layoutmode>physical</layoutmode>
          <logicalmonitor>
            <x>0</x>
            <y>0</y>
            <scale>1</scale>
            <primary>yes</primary>
            <monitor>
              <monitorspec>
                <connector>DP-4</connector>
                <vendor>SAM</vendor>
                <product>Odyssey G95SC</product>
                <serial>H1AK500000</serial>
              </monitorspec>
              <mode>
                <width>5120</width>
                <height>1440</height>
                <rate>239.999</rate>
              </mode>
              <colormode>bt2100</colormode>
            </monitor>
          </logicalmonitor>
        </configuration>
      </monitors>
    ''}"
  ];

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
    gnome.excludePackages = with pkgs; [
      yelp
    ];

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
      adwaita-icon-theme
      dconf-editor
      wl-clipboard
      xdg-utils
      gnome-tweaks
      gnome-extension-manager
      gnomeExtensions.dash-to-panel
      gnomeExtensions.appindicator
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
      mangohud
      protonup-qt
    ];

    variables = {
      CUDA_PATH = "${pkgs.cudatoolkit}";
    };
  };

  services.udev.packages = [ pkgs.yubikey-personalization ];

  networking.firewall.enable = false;

  nix = {
    buildMachines = lib.mkForce [ ];
    distributedBuilds = lib.mkForce false;
  };

  system.stateVersion = "25.11";
}
