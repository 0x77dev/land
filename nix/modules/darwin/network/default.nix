{
  lib,
  namespace,
  ...
}:
{
  networking = lib.mkDefault lib.${namespace}.shared.network-config;
}
