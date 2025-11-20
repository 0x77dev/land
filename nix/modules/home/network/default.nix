{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.network;
in
{
  options.modules.home.network = {
    enable = mkEnableOption "network";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wireshark
      skopeo
      mosquitto
      iperf3
    ];
  };
}
