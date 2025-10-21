{ nixpkgs
, nixpkgs-unstable
, home-manager
, nixvim
, ...
}@inputs:
{ system
, username
, homeDirectory
, modules ? [ ]
}:

home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  modules = [
    ../modules/home
    {
      home.username = username;
      home.homeDirectory = homeDirectory;
    }
  ] ++ modules;

  extraSpecialArgs = {
    inherit inputs system;
    pkgsUnstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  };
}
