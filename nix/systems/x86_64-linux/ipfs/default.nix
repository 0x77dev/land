# Before using this configuration, you MUST read and understand the NOTICE file
# in this directory. By using this software, you agree to be bound by its terms.
# See: ./NOTICE for complete legal disclaimer and terms of use.
{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.05";

  # Sops secrets configuration
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # WireGuard secrets
    secrets = {
      "wg/private_key" = { };
      "wg/address" = { };
      "wg/endpoint" = { };
      "wg/public_key" = { };
      "wg/dns" = { };
    };

    # Generate WireGuard config from secrets template
    templates."wg0.conf" = {
      content = ''
        [Interface]
        PrivateKey = ${config.sops.placeholder."wg/private_key"}
        Address = ${config.sops.placeholder."wg/address"}
        DNS = ${config.sops.placeholder."wg/dns"}

        [Peer]
        PublicKey = ${config.sops.placeholder."wg/public_key"}
        Endpoint = ${config.sops.placeholder."wg/endpoint"}
        AllowedIPs = 0.0.0.0/0, ::/0
        PersistentKeepalive = 25
      '';
      mode = "0600";
    };
  };

  # VPN network namespace configuration
  vpnNamespaces.ipfs = {
    enable = true;
    wireguardConfigFile = config.sops.templates."wg0.conf".path;
    accessibleFrom = [
      "192.168.0.0/16"
    ];
    # Port mappings for IPFS services
    portMappings = [
      {
        from = 4001;
        to = 4001;
        protocol = "both";
      } # Swarm
      {
        from = 5001;
        to = 5001;
      } # API
      {
        from = 8080;
        to = 8080;
      } # Gateway
    ];
  };

  # Services configuration
  services = {
    # Kubo (IPFS) configuration
    kubo = {
      enable = true;
      enableGC = true;
      autoMount = true;
      # Allow access to API/Gateway from outside the container (via port forwarding)
      settings = {
        Addresses = {
          API = "/ip4/0.0.0.0/tcp/5001";
          Gateway = "/ip4/0.0.0.0/tcp/8080";
        };
      };
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };

  virtualisation.incus.agent.enable = true;

  # VPN Confinement for IPFS service
  # The systemd service name for kubo is 'ipfs'
  systemd.services.ipfs.vpnConfinement = {
    enable = true;
    vpnNamespace = "ipfs";
  };

  security.sudo.wheelNeedsPassword = false;

  users = {
    users = {
      mykhailo = {
        isNormalUser = true;
        description = "Mykhailo Marynenko";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
        shell = pkgs.fish;
      };
    };
  };

  # Additional tools
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # Networking
  networking = {
    hostName = "ipfs";
    domain = "0x77.computer";
    useDHCP = true;
    firewall.enable = false;
  };

  # User configuration
  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home = {
      enable = true;
      config = { };
    };
  };
}
