{ pkgs
, inputs
, lib
, pkgsUnstable
, ...
}:
let
  ghostty = if pkgs.stdenv.isDarwin then pkgsUnstable.ghostty-bin else pkgs.ghostty;
in
{
  programs.ghostty = {
    package = ghostty;
    settings = {
      font-family = "TX-02-Variable";
      font-variation = "wght=600";
      font-size = 16;
      font-feature = "+calt,+liga";
      theme = "github-dark-default";
    };
  };

  home.packages = [ ghostty ];
}
