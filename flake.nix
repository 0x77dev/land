{
  description = "@0x77dev homelab/machines land";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    devenv.url = "github:cachix/devenv/v1.7";

    nix2container.url = "github:nlewo/nix2container";
    nix2container.inputs.nixpkgs.follows = "nixpkgs";

    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
    nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";

    # Apple Silicon (Asahi) support for NixOS
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # VS Code Server
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # WSL specific inputs
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # darwin specific inputs
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
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
    homebrew-assemblyai = {
      url = "github:assemblyai/homebrew-assemblyai";
      flake = false;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw= land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA= cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=";
    extra-substituters = "https://devenv.cachix.org https://land.cachix.org https://cache.lix.systems";
    warn-dirty = false;
    allow-unfree = true;
  };

  outputs =
    inputs@{ flake-parts
    , devenv-root
    , sops-nix
    , nix-darwin
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , nixos-generators
    , nixos-wsl
    , nixos-vscode-server
    , disko
    , nixos-anywhere
    , lix-module
    , nvf
    , ...
    }:
    let
      mkHomeConfig =
        { system
        , username
        , homeDirectory
        , modules ? [ ]
        ,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          modules = [
            nvf.homeManagerModules.default
            ./modules/home
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ] ++ modules;

          extraSpecialArgs = {
            inherit inputs system;
          };
        };

      mkDarwinConfig =
        { system ? "aarch64-darwin"
        , modules ? [ ]
        ,
        }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            lix-module.nixosModules.default
            sops-nix.darwinModules.sops
            ./modules/darwin/homebrew.nix
            ./modules/darwin/security.nix
            ./modules/darwin/dock.nix
            ./modules/darwin/linux-builder.nix
            ./modules/darwin/hardware/focusrite.nix
            ./modules/darwin/hardware/flipper.nix
            ./modules/darwin/hardware/meshtastic.nix
            ./systems/darwin/common/configuration.nix
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hmbak";
                extraSpecialArgs = {
                  inherit inputs system;
                };
                users."0x77" = import ./modules/home {
                  inherit inputs system;
                  username = "0x77";
                  homeDirectory = "/Users/0x77";
                  openssh.authorizedKeys.keys = builtins.fromJSON (
                    builtins.readFile ./helpers/openssh-authorized-keys.json
                  );
                };
              };
            }
          ] ++ modules;
        };

      mkNixosModules =
        { system
        , modules ? [ ]
        ,
        }:
        [
          lix-module.nixosModules.default
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
              users."mykhailo" = import ./modules/home {
                inherit inputs system;
                username = "mykhailo";
                homeDirectory = "/home/mykhailo";
                openssh.authorizedKeys.keys = builtins.fromJSON (
                  builtins.readFile ./helpers/openssh-authorized-keys.json
                );
              };
            };
          }
        ]
        ++ modules;

      mkNixosConfig =
        { system
        , modules ? [ ]
        ,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules =
            mkNixosModules { inherit system modules; }
            ++ [
              nixos-generators.nixosModules.all-formats
            ]
            ++ modules;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "i686-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { config
        , self'
        , inputs'
        , pkgs
        , system
        , ...
        }:
        {
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
          "0x77@potato" = mkHomeConfig {
            system = "aarch64-darwin";
            username = "0x77";
            homeDirectory = "/Users/0x77";
          };
          "mykhailo@tomato" = mkHomeConfig {
            system = "x86_64-linux";
            username = "mykhailo";
            homeDirectory = "/home/mykhailo";
          };
          "mykhailo@muscle" = mkHomeConfig {
            system = "x86_64-linux";
            username = "mykhailo";
            homeDirectory = "/home/mykhailo";
            modules = [{ targets.genericLinux.enable = true; }];
          };
        };

        nixosConfigurations = {
          vanilla = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              nixos-generators.nixosModules.all-formats
              { nixpkgs.config.allowUnfree = true; }
            ];
          };

          muscleWSL = mkNixosConfig {
            system = "x86_64-linux";
            modules = [
              nixos-wsl.nixosModules.default
              ./systems/nixos/muscle-wsl/configuration.nix
            ];
          };

          attic = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };
            modules = [
              nixos-generators.nixosModules.all-formats
              ./containers/attic/configuration.nix
              {
                proxmox.lxc.enable = true;
                nixpkgs.config.allowUnfree = true;
              }
            ] ++ (import ./modules/nixos);
          };

          beefy = mkNixosConfig {
            system = "aarch64-linux";
            modules = [
              ./systems/nixos/beefy/configuration.nix
            ];
          };
        };

        darwinConfigurations = {
          common = mkDarwinConfig {
            system = "aarch64-darwin";
          };

          potato = mkDarwinConfig {
            system = "aarch64-darwin";
          };
        };
      };
    };
}
