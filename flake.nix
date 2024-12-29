{
  description = "@0x77dev homelab/machines land";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    devenv.url = "github:cachix/devenv";
    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";
    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # darwin specific inputs
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    lyraphase-av-casks = {
      url = "github:LyraPhase/homebrew-av-casks";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA=";
    extra-substituters = "https://devenv.cachix.org https://land.cachix.org";
    warn-dirty = false;
    allow-unfree = true;
  };

  outputs = inputs@{ flake-parts, devenv-root, nix-darwin, nixpkgs, home-manager, nixos-generators, ... }:
    let
      mkHomeConfig = system: username: homeDirectory: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
        };

        modules = [
          ./modules/home
          {
            home.username = username;
            home.homeDirectory = homeDirectory;
          }
        ];

        extraSpecialArgs = {
          inherit inputs system;
        };
      };

      mkDarwinConfig = { system ? "aarch64-darwin", modules ? [ ] }: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./modules/darwin/homebrew.nix
          ./modules/darwin/security.nix
          ./modules/darwin/dock.nix
          ./modules/darwin/linux-builder.nix
          ./modules/darwin/hardware/focusrite.nix
          ./modules/darwin/hardware/flipper.nix
          ./modules/darwin/hardware/meshtastic.nix
          ./modules/darwin/hardware/worklouder.nix
          ./systems/darwin/common/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs system;
              };
              users."0x77" = import ./modules/home {
                inherit inputs system;
                username = "0x77";
                homeDirectory = "/Users/0x77";
              };
            };
          }
        ] ++ modules;
      };

      mkNixosModules = { system, modules ? [ ] }: [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs system;
            };
          };
        }
      ] ++ modules;

      mkNixosConfig = { system, modules ? [ ] }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = mkNixosModules { inherit system modules; } ++ [
          nixos-generators.nixosModules.all-formats
          {
            formatConfigs.install-iso = { modulesPath, ... }: {
              imports = [ "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix" ];
              formatAttr = "isoImage";
              fileExtension = ".iso";
            };
          }
        ] ++ modules;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        devenv.shells.default = {
          devenv.root =
            let
              devenvRootFileContent = builtins.readFile devenv-root.outPath;
            in
            pkgs.lib.mkIf (devenvRootFileContent != "") devenvRootFileContent;

          name = "land";
          imports = [
            ./devenv.nix
          ];
        };
      };

      flake = {
        homeConfigurations = {
          "0x77@beefy" = mkHomeConfig "aarch64-darwin" "0x77" "/Users/0x77";
          "0x77@potato" = mkHomeConfig "aarch64-darwin" "0x77" "/Users/0x77";
          "mykhailo@tomato" = mkHomeConfig "x86_64-linux" "mykhailo" "/home/mykhailo";
        };

        nixosConfigurations = {
          tomato = mkNixosConfig {
            system = "x86_64-linux";
            modules = [
              ./systems/nixos/tomato/configuration.nix
            ];
          };
        };

        darwinConfigurations = {
          common = mkDarwinConfig {
            system = "aarch64-darwin";
          };

          beefy = mkDarwinConfig {
            system = "aarch64-darwin";
          };

          potato = mkDarwinConfig {
            system = "aarch64-darwin";
          };
        };
      };
    };
}
