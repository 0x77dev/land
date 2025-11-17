{
  lib,
  namespace,
  ...
}:
{
  home = lib.${namespace}.shared.home-config { inherit lib; };

  programs.home-manager.enable = true;
}
