{
  lib,
  namespace,
  pkgs,
  ...
}:
{
  nix = lib.${namespace}.shared.nix-config { inherit pkgs; };
}
