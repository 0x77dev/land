_: {
  # Fetch and process a Grafana dashboard from grafana.com by ID and version
  # Replaces DS_PROMETHEUS datasource placeholder with actual datasource
  # Usage: lib.land.shared.grafana-dashboards.fetch { pkgs, id, version, hash, name ? null, datasource ? "Prometheus" }
  fetch =
    {
      pkgs,
      id,
      version,
      hash,
      name ? "dashboard-${toString id}.json",
      datasource ? "Prometheus",
    }:
    pkgs.runCommand name
      {
        src = pkgs.fetchurl {
          inherit hash;
          name = "raw-${name}";
          url = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString version}/download";
        };
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        # Process dashboard JSON:
        # 1. Replace ALL prometheus datasource references with our datasource name
        # 2. Remove __inputs and __requires (import metadata)
        # 3. Set id to null (let Grafana assign)
        jq '
          walk(
            if type == "object" and has("datasource") and (.datasource | type) == "object" and .datasource.type == "prometheus" then
              .datasource.uid = "${datasource}"
            else
              .
            end
          ) |
          del(.__inputs) |
          del(.__requires) |
          .id = null
        ' "$src" > "$out"
      '';

  # Fetch and process a dashboard from a URL (not grafana.com)
  # Usage: lib.land.shared.grafana-dashboards.fetchUrl { pkgs, url, hash, name ? null, datasource ? "Prometheus" }
  fetchUrl =
    {
      pkgs,
      url,
      hash,
      name ? "dashboard.json",
      datasource ? "Prometheus",
    }:
    pkgs.runCommand name
      {
        src = pkgs.fetchurl { inherit url hash; };
        nativeBuildInputs = [ pkgs.jq ];
      }
      ''
        jq '
          walk(
            if type == "object" and has("datasource") and (.datasource | type) == "object" and .datasource.type == "prometheus" then
              .datasource.uid = "${datasource}"
            else
              .
            end
          ) |
          del(.__inputs) |
          del(.__requires) |
          .id = null
        ' "$src" > "$out"
      '';

  # Common dashboard definitions with pre-computed hashes
  dashboards = {
    # Node Exporter Full - comprehensive system metrics
    # https://grafana.com/grafana/dashboards/1860
    node-exporter-full = {
      id = 1860;
      version = 37;
      hash = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
      name = "node-exporter-full.json";
    };

    # Chrony exporter dashboard
    # https://grafana.com/grafana/dashboards/19186
    chrony = {
      id = 19186;
      version = 2;
      hash = "sha256-Etm7ZE7ISqh/w/HIxKAUOPJl5Sb+jRUneveuYfLOr0A=";
      name = "chrony.json";
    };
  };

  # URLs for dashboards not on grafana.com
  urls = {
    # GPSD exporter dashboard from upstream repo
    gpsd-exporter = {
      url = "https://raw.githubusercontent.com/natesales/gpsd-exporter/main/grafana-dashboard.json";
      hash = "sha256-2euVt4szSjc5U5jAWuzRzNQcYmrWfLNcdgZPp24y058=";
    };
  };
}
