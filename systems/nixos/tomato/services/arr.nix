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

  services.lidarr = {
    enable = true;
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };
}
