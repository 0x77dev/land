{ pkgs, ... }:

{
  services = {
    netdata.enable = true;
    tailscale.enable = true;
    prometheus.exporters.node.enable = true;
    ipfs.enable = true;
  };

  environment.systemPackages = [ pkgs.ollama ];

  launchd = {
    user = {
      agents.ollama-serve = {
        command = "${pkgs.ollama}/bin/ollama serve";
        serviceConfig = {
          KeepAlive = true;
          RunAtLoad = true;
        };
      };
      envVariables = {
        # Expose ollama on the network
        OLLAMA_HOST = "0.0.0.0";
        # Enable Flash Attention for better performance
        OLLAMA_FLASH_ATTENTION = "1";
      };
    };
  };
}
