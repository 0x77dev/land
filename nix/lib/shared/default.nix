{
  lib,
  inputs,
  namespace,
  ...
}:
{
  nix-config = import ./nix-config { inherit lib inputs namespace; };
  network-config = import ./network-config { inherit lib inputs namespace; };
}
