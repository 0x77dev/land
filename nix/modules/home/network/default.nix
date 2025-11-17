{ pkgs, ... }:
{
  home.packages = with pkgs; [
    wireshark
    skopeo
    mosquitto
    iperf3
  ];
}
