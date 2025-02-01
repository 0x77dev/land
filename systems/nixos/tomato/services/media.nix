{ pkgs, ... }: {
  services.immich = {
    enable = false;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    mediaLocation = "/data/media/immich";
  };

  services.plex = {
    enable = true;
    openFirewall = true;
  };

  services.tautulli = {
    enable = true;
    openFirewall = true;
    port = 33000;
  };
}
