{ nixpkgs
, nixpkgs-unstable
, nix-darwin
, home-manager
, sops-nix
, ...
}@inputs:
{ system ? "aarch64-darwin"
, modules ? [ ]
}:

nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit inputs;
    pkgsUnstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  };

  modules = [
    sops-nix.darwinModules.sops
    ../modules/darwin/homebrew.nix
    ../modules/darwin/security.nix
    ../modules/darwin/dock.nix
    ../modules/darwin/linux-builder.nix
    ../modules/darwin/hardware/flipper.nix
    ../modules/darwin/hardware/uad.nix
    ../modules/darwin/hardware/meshtastic.nix
    ../systems/darwin/common/configuration.nix
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hmbak";
        extraSpecialArgs = {
          inherit inputs system;
          pkgsUnstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
        users."0x77" = import ../modules/home {
          inherit inputs system;
          username = "0x77";
          homeDirectory = "/Users/0x77";
          openssh.authorizedKeys.keys = builtins.fromJSON (
            builtins.readFile ../helpers/openssh-authorized-keys.json
          );
        };
      };
    }
  ] ++ modules;
}
