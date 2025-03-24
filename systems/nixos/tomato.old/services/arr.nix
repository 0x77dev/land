{ pkgs, ... }: {
  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  services.sonarr = {
    enable = true;
    openFirewall = true;
    package = pkgs.sonarr.overrideAttrs (old: {
      doCheck = false;
      doInstallCheck = false;
    });
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      flaresolverr = {
        autoStart = true;
        image = "flaresolverr/flaresolverr:latest";
        ports = [ "127.0.0.1:8191:8191" ];
        environment = {
          LOG_LEVEL = "info";
          LOG_HTML = "false";
          TZ = "America/Los_Angeles";
        };
      };
    };
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.bazarr = {
    enable = true;
    openFirewall = true;
  };

  services.readarr = {
    enable = true;
    openFirewall = true;
  };
}
