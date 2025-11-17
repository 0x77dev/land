{ pkgs, ... }:
{
  home.packages = with pkgs; [
    binwalk
    raider
    flashprog
    sasquatch
    dcfldd
    p7zip
    pigz
    pv
  ];
}
