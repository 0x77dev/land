{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./disko-config.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480
  ];

  modules = {
    cachix-deploy = {
      enable = true;
      agentName = "ghost";
    };
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
      autoSnapshot.enable = true;
    };
    observability = {
      enable = false;
      openFirewall = false;
    };
    security-tools.enable = true;
    vscode-server.enable = true;
  };

  networking = {
    hostName = "ghost";
    domain = "0x77.computer";
    hostId = "edbcf5ac";
    networkmanager.enable = true;
    useDHCP = lib.mkForce true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.systemd = {
      enable = true;
      services.rollback-root = {
        description = "Rollback ephemeral root dataset";
        wantedBy = [ "initrd.target" ];
        after = [ "zfs-import-zroot.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          if ${config.boot.zfs.package}/bin/zfs list -H -t snapshot zroot/root@blank >/dev/null 2>&1; then
            ${config.boot.zfs.package}/bin/zfs rollback -r zroot/root@blank
          else
            ${config.boot.zfs.package}/bin/zfs snapshot zroot/root@blank
          fi
        '';
      };
    };

    zfs.unsafeAllowHibernation = false;

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
    consoleLogLevel = 3;
    kernel.sysctl = {
      "fs.protected_fifos" = 2;
      "fs.protected_hardlinks" = 1;
      "fs.protected_regular" = 2;
      "fs.protected_symlinks" = 1;
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.yama.ptrace_scope" = 1;
      "net.core.bpf_jit_harden" = 2;
      "vm.swappiness" = 10;
    };
  };

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
      settings.General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };
    chromium = {
      enable = true;
      extensions = [
        "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
      ];
    };
    dconf.enable = true;
    nix-ld.enable = true;
  };

  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

    xserver = {
      enable = true;
      xkb.layout = "us";
      excludePackages = with pkgs; [ xterm ];
    };

    gnome.gnome-remote-desktop.enable = false;

    power-profiles-daemon.enable = false;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
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

    fprintd.enable = true;
    fwupd.enable = true;
    pcscd.enable = true;

    time-client = {
      enable = true;
      server = "timey.0x77.computer";
    };

    illum.enable = true;

    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
    };
  };

  security = {
    apparmor.enable = true;
    audit.enable = true;
    auditd.enable = true;
    polkit.enable = true;
    rtkit.enable = true;
    sudo.wheelNeedsPassword = lib.mkDefault true;
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

  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    fwupd
    gnome-tweaks
    google-chrome
    hwloc
    libfido2
    opensc
    vim
    xdg-utils
  ];

  system.stateVersion = "25.11";
}
