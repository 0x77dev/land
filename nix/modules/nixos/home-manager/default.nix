{
  lib,
  namespace,
  ...
}:
{
  home-manager = lib.${namespace}.shared.home-manager-config { inherit lib; };
}
