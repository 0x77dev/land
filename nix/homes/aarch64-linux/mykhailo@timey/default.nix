{
  lib,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  programs.home-manager.enable = true;

  inherit (shared) home;
  modules.home = shared.modules.home;
}
