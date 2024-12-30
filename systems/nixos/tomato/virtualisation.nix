{ ... }: {
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      data-root = "/data/docker";
    };
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
