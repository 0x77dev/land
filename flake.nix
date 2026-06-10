{
  description = "0x77dev's land";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "unstable";
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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "unstable";
    };

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # CachyOS kernel with BORE scheduler
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  outputs =
    inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      # flake-utils-plus detects Nixpkgs channels by probing legacyPackages,
      # which forces nixpkgs' x86_64-darwin deprecation warning in 26.05. Give
      # Snowfall a channel probe that preserves the input source without forcing
      # the whole legacy package matrix.
      channelProbe.legacyPackages.x86_64-linux.nix = null;
      inputsForSnowfall = inputs // {
        self = inputs.self // {
          inherit (outputs) pkgs;
        };
        nixpkgs = inputs.nixpkgs // channelProbe;
        unstable = inputs.unstable // channelProbe;
      };

      # Shared treefmt config (single source of truth) — also consumed by the
      # dev shell and the pre-commit `treefmt` hook via `lib.land.treefmt`.
      treefmt = import ./nix/lib/treefmt/default.nix { inherit inputs; };

      lib = inputs.snowfall-lib.mkLib {
        inputs = inputsForSnowfall;
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
        inherit supportedSystems;

        channels-config.allowUnfree = true;

        # `nix fmt` runs treefmt via the shared config (single source of truth).
        outputs-builder = channels: {
          formatter = (treefmt.mkEval channels.nixpkgs).config.build.wrapper;
        };

        overlays = with inputs; [
          # Snowfall Lib/flake-utils-plus still read `pkgs.system`; shadow the
          # deprecated nixpkgs alias with the replacement value until upstream
          # stops doing so.
          (final: _prev: {
            system = final.stdenv.hostPlatform.system;
          })
          nixos-raspberrypi.overlays.bootloader
          nixos-raspberrypi.overlays.vendor-kernel
          nixos-raspberrypi.overlays.vendor-firmware
          nixos-raspberrypi.overlays.kernel-and-firmware
          nixos-raspberrypi.overlays.vendor-pkgs
          nix-cachyos-kernel.overlays.pinned
        ];

        systems = {
          modules = {
            darwin = with inputs; [
              nix-homebrew.darwinModules.nix-homebrew
            ];

            nixos = with inputs; [
              disko.nixosModules.disko
              nixos-vscode-server.nixosModules.default
              vpn-confinement.nixosModules.default
            ];
          };

          hosts = {
            timey.specialArgs = {
              inherit (inputs) nixos-raspberrypi;
            };

            # microvm.nix stays per-host: spark hosts VMs, vasyl is a guest.
            spark.modules = with inputs; [
              microvm.nixosModules.host
            ];
            vasyl.modules = with inputs; [
              microvm.nixosModules.microvm
              hermes-agent.nixosModules.default
            ];
          };
        };
      };

      automation = outputs.lib.automation.mkOutputs { inherit outputs; };
    in
    (removeAttrs outputs [
      "pkgs"
      "snowfall"
    ])
    // {
      lib = outputs.lib // {
        automation = outputs.lib.automation // automation;
      };
    };
}
