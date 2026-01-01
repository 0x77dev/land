{
  pkgs,
  lib,
  namespace,
  inputs,
  ...
}:
{
  imports = [
    ./disko-config.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
  ];

  networking = {
    hostName = "ghost";
    domain = "0x77.computer";
    useDHCP = lib.mkForce true;
  };

  boot = {
    supportedFilesystems = [
      "ntfs"
      "ext2"
    ];
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    consoleLogLevel = 3;
    loader = {
      systemd-boot.enable = false;
      grub.enable = true;
      # Device is set by disko based on disk configuration
    };
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.overcommit_memory" = 1;
      "vm.overcommit_ratio" = 100;
    };
  };

  # T480 has 16GB RAM max - use swap file for suspend/hibernate
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # 16GB for hibernation
      discardPolicy = "once";
    }
  ];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
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

  # Laptop-specific power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Disable sleep/suspend (optional: keep laptop always on)
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  nixpkgs.config.allowUnfree = true;

  # Cinnamon uses GTK, no Qt needed
  programs = {
    dconf.enable = true;

    appimage = {
      enable = true;
      binfmt = true;
    };

    chromium.enable = true;
    fish.enable = true;
  };

  services = {
    # Enable TLP for better battery life on laptop
    power-profiles-daemon.enable = false; # Disable conflicting service
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    xserver = {
      enable = true;
      xkb.layout = "us";
      # Cinnamon desktop environment
      desktopManager.cinnamon.enable = true;
      displayManager.lightdm = {
        enable = true;
        greeters.slick = {
          enable = true;
          theme.name = "Mint-Y-Dark";
        };
      };
    };

    # Cinnamon services
    cinnamon.apps.enable = true;

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

    # Smart card support (Yubikey)
    pcscd.enable = true;

    # Time synchronization
    time-client = {
      enable = true;
      server = "timey.0x77.computer";
    };

    # Laptop-specific: automatic backlight adjustment
    illum.enable = true;

    # Touchpad support
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };

    tailscale.enable = true;
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

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
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.fish;
  };

  fonts.fontconfig.enable = true;

  environment = {
    # Exclude some default Cinnamon apps we don't need
    cinnamon.excludePackages = with pkgs.cinnamon; [
      # Keep most apps for now, can trim later
    ];

    systemPackages = with pkgs; [
      btop
      fastfetch
      hwloc
      chromium
      pkgs.${namespace}.tx-02-variable
      gitFull
      vim
      libfido2
      opensc
      ghostty
      xdg-utils
    ];
  };

  networking.firewall.enable = true;

  system.stateVersion = "25.11";
}
