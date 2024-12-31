{ pkgs, ... }: {
  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
}
