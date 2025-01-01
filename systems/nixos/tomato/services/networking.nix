{ pkgs, ... }: {
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;
  services.fail2ban.enable = true;

  services.cloudflared = {
    enable = true;
    tunnels = {
      "e87e4617-7110-4173-a025-b93460868081" = {
        credentialsFile = "/run/secrets/cloudflared/credentials";
        ingress = {
          "plausible.0x77.computer" = "http://127.0.0.1:8181";
          "plex.0x77.computer" = "http://127.0.0.1:32400";
        };
        default = "http_status:404";
      };
    };
  };

  users.users.cloudflared.home = "/home/cloudflared";
}
