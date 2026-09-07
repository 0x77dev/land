# Before using this configuration, you MUST read and understand the NOTICE file
# in the parent directory. By using this software, you agree to be bound by its
# terms. See: ../NOTICE for complete legal disclaimer and terms of use.
{ inputs, ... }:
let
  # Kubo runs in its own network namespace (privateNetwork) so its wgcf
  # namespace and 192.168.15.x veth are isolated from the media stack, which
  # shares the host netns. Its peering is the explicit Cloudflare list, so it
  # needs no LAN broadcast; the host reaches kubo via forwardPorts.
  containerConfig =
    { lib, inputs, ... }:
    {
      imports = [
        inputs.vpn-confinement.nixosModules.default
        ../../../../modules/nixos/wgcf
      ];

      system.stateVersion = "25.11";

      networking = {
        # Private netns gated by host forwardPorts; the container's own
        # firewall adds nothing and tailscale serve terminates on localhost.
        # Disabled for parity with the media container's posture.
        firewall.enable = false;
        hostName = lib.mkForce "ipfs-container";
        # resolv.conf workaround for nspawn private networks (nixpkgs#162686);
        # the container uses the host's resolver otherwise.
        useHostResolvConf = lib.mkForce false;
      };

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
            # Never probe NAT-PMP/UPnP; the only inbound path is the explicit
            # wgcf port mapping below.
            Swarm.DisableNatPortMap = true;
          }
          // (lib.importJSON ./peering/cloudflare.json);
        };
      };

      # Confine every Kubo flow (swarm, DHT, bootstrap, DNS) to the WARP
      # namespace so the host's real IP is never exposed to the swarm. The
      # systemd service name for kubo is 'ipfs'.
      systemd.services.ipfs.vpnConfinement = {
        enable = true;
        vpnNamespace = "wgcf";
      };

      services.resolved.enable = true;

      # Own tailnet identity. Userspace mode (no /dev/net/tun in the nested
      # netns). tailscale serve terminates on localhost and proxies to kubo at
      # the wgcf namespace veth address (192.168.15.1) — bypassing the wgcf
      # accessibleFrom source filter, which only covers 192.168.0.0/16 and
      # would blackhole 100.64.0.0/10 tailnet traffic. Serve is TCP-only, so
      # the QUIC/UDP swarm port 4001 is not exposed here.
      services.tailscale = {
        enable = true;
        interfaceName = "userspace-networking";
      };
      services.tailscale.serve = {
        enable = true;
        services.ipfs = {
          endpoints = {
            "tcp:5001" = "http://192.168.15.1:5001"; # kubo API
            "tcp:8080" = "http://192.168.15.1:8080"; # kubo gateway
          };
        };
      };
    };
in
{
  containers.ipfs = {
    autoStart = true;
    # Private network namespace: kubo's wgcf namespace and its 192.168.15.x
    # veth live entirely inside this container, physically isolated from the
    # media stack's shared host netns.
    privateNetwork = true;
    # Point-to-point veth underlay. 10.89.x avoids the LAN-side
    # 192.168.0.0/16 (wgcf accessibleFrom) and the VPN 192.168.15.x the
    # namespace uses for its veth pair, so the addresses never collide.
    hostAddress = "10.89.0.1";
    localAddress = "10.89.0.2";
    # /dev/net/tun + CAP_NET_ADMIN for the wgcf WireGuard namespace;
    # CAP_SYS_ADMIN so `ip netns` can create the named namespace.
    enableTun = true;
    additionalCapabilities = [
      "CAP_NET_ADMIN"
      "CAP_SYS_ADMIN"
    ];
    privateUsers = "no";
    specialArgs = { inherit inputs; };
    # Host→container port forwards for the kubo API/Gateway/swarm. The swarm
    # port is forwarded for LAN-reachable pinning; internet ingress still
    # comes via the WARP namespace only.
    forwardPorts = [
      {
        containerPort = 4001;
        hostPort = 4001;
        protocol = "tcp";
      }
      {
        containerPort = 4001;
        hostPort = 4001;
        protocol = "udp";
      }
      {
        containerPort = 5001;
        hostPort = 5001;
        protocol = "tcp";
      }
      {
        containerPort = 8080;
        hostPort = 8080;
        protocol = "tcp";
      }
    ];
    # FUSE for Kubo's /ipfs + /ipns autoMount.
    bindMounts."/dev/fuse" = {
      hostPath = "/dev/fuse";
      isReadOnly = false;
    };
    allowedDevices = [
      {
        node = "/dev/fuse";
        modifier = "rw";
      }
    ];
    config = containerConfig;
  };
}
