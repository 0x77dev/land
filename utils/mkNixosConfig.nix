{ nixpkgs
, nixpkgs-unstable
, nixos-generators
, ...
}@inputs:
{ system
, modules ? [ ]
}:

let
  mkNixosModules = import ./mkNixosModules.nix inputs;
in
nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs;
  };

  modules = mkNixosModules { inherit system modules; } ++ [
    nixos-generators.nixosModules.all-formats
  ] ++ modules;
}
