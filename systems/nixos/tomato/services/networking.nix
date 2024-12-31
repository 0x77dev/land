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
  };
}
