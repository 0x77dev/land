{ pkgs, ... }: {
  services.postgresql = {
    enable = true;
    dataDir = "/data/postgresql";
  };
}
