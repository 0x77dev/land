{ pkgs, ... }: {
  services.netdata = {
    enable = true;
    enableAnalyticsReporting = false;
    package = pkgs.netdata.override {
      withCloudUi = true;
    };
    configDir."python.d.conf" = pkgs.writeText "python.d.conf" ''
      samba: yes
    '';
  };

  # Configure netdata service
  systemd.services.netdata = {
    # Add samba and sudo to path for python plugin
    path = [ pkgs.samba "/run/wrappers" ];

    # Set minimal capabilities needed for samba monitoring
    serviceConfig.CapabilityBoundingSet = [ "CAP_SETGID" ];
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };
}
