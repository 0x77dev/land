{ pkgs, ... }:

let
  tx-02-variable = pkgs.callPackage ../../packages/tx-02-variable { };
in
{
  home.packages = [
    tx-02-variable
  ];

  fonts.fontconfig.enable = true;
}
