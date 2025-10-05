{ pkgs ? import <nixpkgs> { } }:

{
  tx-02-variable = pkgs.callPackage ./tx-02-variable { };
}
