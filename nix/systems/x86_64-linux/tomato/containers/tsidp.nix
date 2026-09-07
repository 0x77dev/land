{ inputs, ... }:
let
  # tsidp runs its own tsnet node (in-process Tailscale, userspace) with a
  # distinct tailnet identity "tsidp-container" — no services.tailscale or
  # tailscale-serve needed; tsnet exposes the listener on its own node IP.
  containerConfig =
    { lib, ... }:
    {
      system.stateVersion = "25.11";

      networking.hostName = lib.mkForce "tsidp-container";

      services.tsidp = {
        enable = true;
        settings = {
          hostName = "tsidp-container"; # tsnet node name (distinct identity)
          port = 443;
          useLocalTailscaled = false; # default; tsnet spawns its own node
          enableFunnel = false; # set true later for public SaaS reach
        };
      };
    };
in
{
  containers.tsidp = {
    autoStart = true;
    # tsnet dials out over the shared netns; no host veth needed.
    privateNetwork = false;
    privateUsers = "no";
    specialArgs = { inherit inputs; };
    config = containerConfig;
  };
}
