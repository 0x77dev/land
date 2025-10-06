{ nixpkgs
, nixpkgs-unstable
, home-manager
, sops-nix
, ...
}@inputs:
{ system
, modules ? [ ]
}:

[
  sops-nix.nixosModules.sops
  home-manager.nixosModules.home-manager
  {
    nixpkgs.config.allowUnfree = true;
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs system;
      };
      users."mykhailo" = import ../modules/home {
        inherit inputs system;
        username = "mykhailo";
        homeDirectory = "/home/mykhailo";
        openssh.authorizedKeys.keys = builtins.fromJSON (
          builtins.readFile ../helpers/openssh-authorized-keys.json
        );
      };
    };
  }
] ++ modules
