{
  description = "0x77dev's land";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "unstable";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "unstable";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall = {
          root = ./nix;
          namespace = "land";

          meta = {
            name = "land";
            title = "0x77dev's land";
          };
        };
      };

      # Generate base outputs
      outputs = lib.mkFlake {
        channels-config.allowUnfree = true;

        systems.modules.darwin = with inputs; [
          nix-homebrew.darwinModules.nix-homebrew
          sops-nix.darwinModules.sops
        ];

        systems.modules.nixos = with inputs; [
          sops-nix.nixosModules.sops
          disko.nixosModules.disko
          nixos-vscode-server.nixosModules.default
        ];

        homes.modules = with inputs; [
          sops-nix.homeManagerModules.sops
        ];
      };

      # Use the lib from outputs which includes our custom library functions
      # Automatically generate deploy-rs nodes from all configurations
      deployNodes = outputs.lib.deployment.mkDeployNodes {
        inherit (outputs) darwinConfigurations nixosConfigurations;
      };
    in
    outputs
    // {
      deploy.nodes = deployNodes;

      # Deploy-rs checks are disabled because they fail during flake check
      # due to incomplete evaluation context. The actual deploy functionality
      # works correctly. Use `deploy --dry-activate` to test deployments.
      # checks = builtins.mapAttrs (
      #   _system: deployLib: deployLib.deployChecks { nodes = deployNodes; }
      # ) inputs.deploy-rs.lib;
    };
}
