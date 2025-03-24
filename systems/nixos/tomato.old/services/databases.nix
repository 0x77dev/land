{ pkgs, ... }: {
  services.postgresql = {
    enable = true;
    dataDir = "/data/postgresql";
    # Create netdata user and grant monitoring privileges
    initialScript = pkgs.writeText "init-netdata-monitoring.sql" ''
      CREATE USER netdata;
      GRANT pg_monitor TO netdata;
    '';
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };
}
