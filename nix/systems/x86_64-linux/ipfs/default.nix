# Before using this configuration, you MUST read and understand the NOTICE file
# in this directory. By using this software, you agree to be bound by its terms.
# See: ./NOTICE for complete legal disclaimer and terms of use.
{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
  ];

  system.stateVersion = "25.11";

  services = {
    # Cloudflare Warp VPN
    wgcf = {
      enable = true;
      accessibleFrom = [ "192.168.0.0/16" ];
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

    # Kubo (IPFS) configuration
    kubo = {
      enable = true;
      enableGC = true;
      autoMount = true;
      localDiscovery = false;
      settings = {
        Addresses = {
          API = "/ip4/0.0.0.0/tcp/5001";
          Gateway = "/ip4/0.0.0.0/tcp/8080";
        };
      }
      // (lib.importJSON ./peering/cloudflare.json);
    };

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    time-client.enable = true;
  };

  virtualisation.incus.agent.enable = true;

  # VPN Confinement for IPFS service
  # The systemd service name for kubo is 'ipfs'
  systemd.services.ipfs.vpnConfinement = {
    enable = true;
    vpnNamespace = "wgcf";
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.mykhailo = {
    isNormalUser = true;
    description = "Mykhailo Marynenko";
    extraGroups = [
      "wheel"
      "networkmanager"
      "ipfs"
    ];
    shell = pkgs.fish;
  };

  networking = {
    hostName = "ipfs";
    domain = "0x77.computer";
    useDHCP = true;
    firewall.enable = false;
  };

  snowfallorg.users.mykhailo = {
    create = true;
    admin = true;
    home.enable = true;
  };
}
