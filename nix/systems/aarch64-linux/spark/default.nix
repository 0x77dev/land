{
  pkgs,
  namespace,
  ...
}:
{
  networking = {
    hostName = "spark";
    domain = "0x77.computer";
    useDHCP = true;
    firewall.enable = false;
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

  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  programs = {
    dconf.enable = true;
    nix-ld.enable = true;
    fish.enable = true;
  };

  services = {
    xserver.xkb.layout = "us";

    # KDE Plasma 6 on Wayland
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };

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
      "docker"
      "networkmanager"
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

      # KDE apps
      kdePackages.dolphin
      kdePackages.ark
      kdePackages.konsole
      kdePackages.kate
    ];

    variables.CUDA_PATH = "${pkgs.cudatoolkit}";

    # Wayland for Electron/Chromium apps
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  system.stateVersion = "25.11";
}
