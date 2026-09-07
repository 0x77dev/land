{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./disko-config.nix
    ./fde.nix
    ./containers/media.nix
    ./containers/ipfs.nix
    ./containers/tsidp.nix
  ];

  modules = {
    hardware.ms-01.enable = true;
    filesystem.zfs = {
      enable = true;
      useLatestKernel = true;
    };
    observability.enable = true;
    security-tools.enable = true;
    vscode-server.enable = true;
    # Remote dev session persistence.
    zmx.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    liveRestore = true;
    autoPrune.enable = true;
  };
  services = {
    time-client = {
      enable = true;
      ptp = {
        enable = true;
        interface = "enp2s0f0np0"; # First 10GbE NIC
        timestamping = "software"; # Match timey's software timestamping
      };
    };

    # Firmware updates via LVFS.
    fwupd.enable = true;

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

    # Host Tailscale: kernel-mode (tailscale0), performant. Bound services are
    # reachable on the tailnet IP via the kernel route — no `serve` needed here.
    tailscale = {
      enable = true;
      openFirewall = true; # UDP 41641
      useRoutingFeatures = "client"; # checkReversePath = "loose" for exit-node clients
      extraSetFlags = [ "--operator=mykhailo" ]; # CLI/GUI control without sudo
    };

    # UDP GRO forwarding on the physical NIC (Tailscale performance best
    # practice for high-throughput nodes, esp. subnet routers/exit nodes).
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale-optimizations" = {
        onState = [ "routable" ];
        script = ''
          ${lib.getExe pkgs.ethtool} -K enp2s0f0np0 rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
  };

  networking = {
    hostName = "tomato";
    domain = "0x77.computer";
    hostId = "442cbd39";
    # Both 10GbE NICs configured independently via DHCP.
    useDHCP = true;
    # Container stacks share this network namespace; the media stack adds its
    # own allowed ports. ipfs runs in a private network namespace (see
    # containers/ipfs.nix) and reaches the host only via forwardPorts.
    firewall = {
      enable = true;
      # Native nftables (modern, no iptables-compat translation layer).
      # trustedInterfaces lets tailnet traffic to host services through
      # unfiltered (kernel-mode tailscale0 route exposes SSH/zmx).
      trustedInterfaces = [ config.services.tailscale.interfaceName ];
    };
  };

  networking.nftables.enable = true;

  # Force tailscaled onto the nftables backend (avoids iptables-compat issues).
  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  security = {
    sudo.wheelNeedsPassword = false;

    # TPM 2.0 userspace: PKCS#11, TCTI env, and the tss group. Used by
    # systemd-cryptenroll for LUKS auto-unlock once the disks are encrypted.
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
  };

  # lanzaboote replaces systemd-boot and signs everything it installs with the
  # sbctl keys in /var/lib/sbctl (created once with `sbctl create-keys`,
  # enrolled with `sbctl enroll-keys` — our own CA only, no Microsoft keys).
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = true;
  };
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    # Fresh key-only installs need an unlocked shadow entry or sshd rejects
    # even valid authorized keys. Password SSH is disabled independently;
    # set a local password with `passwd` after the first key login.
    initialHashedPassword = "";
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
      "kvm"
      "tss" # TPM 2.0 access via the TCTI environment
    ];
    shell = pkgs.fish;
  };

  environment.systemPackages = with pkgs; [
    ethtool
    # Secure Boot key management (lanzaboote signs with /var/lib/sbctl)
    sbctl
  ];

  system.stateVersion = "25.11";
}
