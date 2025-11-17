{
  lib,
  namespace,
  ...
}:
{
  networking = lib.${namespace}.shared.network-config { inherit lib; };
}
