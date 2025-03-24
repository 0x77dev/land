{ pkgs, ... }: {
  services.kubo = {
    enable = true;
    dataDir = "/data/kubo";
    localDiscovery = true;
    autoMount = true;
    settings = {
      Addresses = {
        API = "/ip4/0.0.0.0/tcp/5001";
        Gateway = "/ip4/0.0.0.0/tcp/8501";
        Swarm = [
          "/ip4/0.0.0.0/tcp/4001"
          "/ip6/::/tcp/4001"
          "/ip4/0.0.0.0/udp/4001/webrtc-direct"
          "/ip4/0.0.0.0/udp/4001/quic-v1"
          "/ip4/0.0.0.0/udp/4001/quic-v1/webtransport"
          "/ip6/::/udp/4001/webrtc-direct"
          "/ip6/::/udp/4001/quic-v1"
          "/ip6/::/udp/4001/quic-v1/webtransport"
        ];
      };
    };
  };

  systemd.services.kubo.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
}
