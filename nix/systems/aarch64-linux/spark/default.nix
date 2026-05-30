{
  pkgs,
  lib,
  namespace,
  ...
}:
let
  muscle = lib.${namespace}.shared.builders.muscle;
in
{
  networking = {
    hostName = "spark";
    domain = "osv.computer";
    # NetworkManager (GNOME's default) handles DHCP — networkd wouldn't lease here.
    networkmanager.enable = true;
    firewall.enable = false;
  };

  systemd = {
    # Always-on appliance — never suspend/hibernate (it serves Ollama/compute).
    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
      AllowSuspendThenHibernate=no
      AllowHybridSleep=no
    '';

    # The nix-daemon authenticates to muscle via the YubiKey, exposed through
    # mykhailo's gpg-agent ssh socket (same as the Darwin hosts' launchd setup).
    # uid 1000 = first normal user (uids are auto-allocated, so not in eval).
    services.nix-daemon.environment.SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
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

  programs = {
    dconf.enable = true;
    nix-ld.enable = true;
    fish.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };

    # Full GNOME on Wayland (gdm defaults to Wayland).
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;

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

    # Ollama with CUDA on the GB10 GPU. Listens on all interfaces (the host
    # firewall is disabled and it's reachable over Tailscale).
    ollama = {
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
    };
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  # Always-on appliance — sleep is inhibited in the `systemd` block above.
  powerManagement.enable = false;

  modules = {
    vscode-server.enable = true;
    observability.enable = true;
    security-tools.enable = true;
  };

  # Offload large/parallel builds to muscle (Threadripper 7985WX) — it
  # out-compiles the Grace cores even on aarch64 via binfmt, and frees the
  # Spark for inference.
  nix = {
    distributedBuilds = true;
    buildMachines = muscle.mkMachines { sshUser = "mykhailo"; };
  };
  programs.ssh.knownHosts.muscle = muscle.knownHost;

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

      gnome-tweaks
    ];

    variables.CUDA_PATH = "${pkgs.cudatoolkit}";

    # Wayland for Electron/Chromium apps
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  system.stateVersion = "25.11";
}
