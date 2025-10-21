{
  description = "@0x77dev homelab/machines land";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv/v1.10";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

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
    , nixvim
    , ...
    }:
    let
      mkHomeConfig = import ./utils/mkHomeConfig.nix inputs;
      mkDarwinConfig = import ./utils/mkDarwinConfig.nix inputs;
      mkNixosModules = import ./utils/mkNixosModules.nix inputs;
      mkNixosConfig = import ./utils/mkNixosConfig.nix inputs;
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
        }: {
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
            modules = [
              { targets.genericLinux.enable = true; }
            ];
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

          rubus = mkNixosConfig {
            system = "aarch64-linux";
            modules = [
              inputs.nixos-hardware.nixosModules.raspberry-pi-4
              ./systems/nixos/rubus/configuration.nix
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
        };

        darwinConfigurations = {
          potato = mkDarwinConfig {
            system = "aarch64-darwin";
          };

          beefy = mkDarwinConfig {
            system = "aarch64-darwin";
            modules = [
              ./systems/darwin/beefy/configuration.nix
            ];
          };
        };
      };
    };
}
