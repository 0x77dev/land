{
  lib,
  inputs,
  namespace,
  ...
}:
{
  nix-config = import ./nix-config { inherit lib inputs namespace; };
  network-config = import ./network-config { inherit lib inputs namespace; };
  home-config = import ./home-config { inherit lib inputs namespace; };
  home-manager-config = import ./home-manager-config { inherit lib inputs namespace; };
  user-config = import ./user-config { inherit lib inputs namespace; };
}
