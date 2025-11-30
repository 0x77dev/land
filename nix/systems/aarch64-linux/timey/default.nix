{
  pkgs,
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  disabledModules = [ (modulesPath + "/rename.nix") ];

  imports = [
    inputs.nixos-raspberrypi.nixosModules.raspberry-pi-5.base
    inputs.nixos-raspberrypi.nixosModules.sd-image
    (lib.mkAliasOptionModule [ "environment" "checkConfigurationOptions" ] [ "_module" "check" ])
  ];

  # Netdata claiming is broken on NixOS (read-only /etc/netdata)
  # time-server module provides netdata without cloud claiming
  modules.observability.enable = false;

  # =============================================================================
  # Network Configuration
  # =============================================================================
  networking = {
    hostName = "timey";
    domain = "0x77.computer";
    hostId = "e205c0de";
    useNetworkd = true;
    networkmanager.enable = lib.mkForce false;
    wireless.enable = lib.mkForce false;
  };

  systemd.network.networks."10-end0" = {
    matchConfig.Name = "end0";
    networkConfig = {
      DHCP = "yes";
      KeepConfiguration = "yes";
    };
    dhcpV4Config.ClientIdentifier = "mac";
    linkConfig.RequiredForOnline = "routable";
  };

  # =============================================================================
  # User Configuration
  # =============================================================================
  security.sudo.wheelNeedsPassword = false;

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.fish;
  };

  # =============================================================================
  # Hardware Configuration (Raspberry Pi 5 + Waveshare NEO-M8T HAT)
  # =============================================================================

  # Disable man pages to save space on SD card
  documentation.man.enable = false;

  boot = {
    # Ensure ethernet driver is loaded early to fix networkd race condition
    initrd.availableKernelModules = [ "macb" ];

    # Downgrade kernel to 6.6.x to avoid PTP bug in 6.12+
    # https://github.com/raspberrypi/linux/issues/5904
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_rpi5_v6_6_31;

    # Disable serial console on ttyAMA0 so GPS can use it
    kernelParams = lib.mkForce [ "console=tty1" ];
  };
  systemd.services."serial-getty@ttyAMA0".enable = false;

  hardware.raspberry-pi.config.all = {
    base-dt-params.uart0 = {
      enable = true;
      value = "on";
    };
    dt-overlays = {
      # Waveshare NEO-M8T HAT routes PPS to GPIO18 (BCM)
      pps-gpio = {
        enable = true;
        params.gpiopin = {
          enable = true;
          value = 18;
        };
      };
      disable-wifi = {
        enable = true;
        params = { };
      };
    };
  };

  # =============================================================================
  # Time Services (GPS + PTP Grandmaster)
  # =============================================================================

  services = {
    gps-time-source = {
      enable = true;
      gpsDevice = "/dev/ttyAMA0";
      ppsDevice = "/dev/pps0";
      ppsGpioPin = 18;
    };

    ptp-grandmaster = {
      enable = true;
      interface = "end0";
      clockClass = 6; # GPS-synced primary reference
      timeSource = "0x10"; # Atomic clock (GPS-disciplined)
      timestamping = "software"; # RPi 5 kernel 6.6 has PTP HW issues
      tuneCoalescing = false; # Not needed for software timestamping
    };

    time-server = {
      enable = true;
      instanceName = "timey";
    };
  };

  # =============================================================================
  # SSH Configuration
  # =============================================================================
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowAgentForwarding = true;
      StreamLocalBindUnlink = true;
    };
  };

  system.stateVersion = "25.05";
}
