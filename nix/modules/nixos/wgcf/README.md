# wgcf

Cloudflare Warp VPN using [wgcf](https://github.com/ViRb3/wgcf).

Creates a `wgcf` network namespace for use with [VPN-Confinement](https://github.com/Maroka-chan/VPN-Confinement).

## Usage

```nix
services.wgcf = {
  enable = true;
  accessibleFrom = [ "192.168.0.0/16" ];
  portMappings = [
    { from = 8080; to = 8080; }
  ];
};

# Confine a service to the VPN
systemd.services.myservice.vpnConfinement = {
  enable = true;
  vpnNamespace = "wgcf";
};
```

## Testing

```bash
# Check VPN status
sudo ip netns exec wgcf wg show

# Verify Warp is active
sudo ip netns exec wgcf curl https://cloudflare.com/cdn-cgi/trace
```
