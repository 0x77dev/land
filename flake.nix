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

    cachix-deploy-flake = {
      url = "github:cachix/cachix-deploy-flake/f363e7ba6661f0e342707b98224c85599fdfb1cc";
      inputs = {
        darwin.follows = "darwin";
        disko.follows = "disko";
        home-manager.follows = "home-manager";
        nixos-anywhere.follows = "nixos-anywhere";
        nixpkgs.follows = "nixpkgs";
      };
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

    # Hermes owns both its official package and NixOS service module.
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "unstable";
    };

    # Centrally maintained, daily-updated AI agent packages. Keep its pinned
    # nixpkgs so Numtide's binary cache remains usable on our stable channel.
    llm-agents.url = "github:numtide/llm-agents.nix";

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # CachyOS kernel with BORE scheduler
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Raycast-style launcher. No nixpkgs follows: that would miss its cache.
    vicinae.url = "github:vicinaehq/vicinae";

    # Push-to-talk voice-to-text.
    voxtype.url = "github:peteonrails/voxtype";

    # UEFI Secure Boot via signed UKIs (sbctl keys).
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://land.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
      "https://nixos-raspberrypi.cachix.org"
      "https://vicinae.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
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

      muscleLocalSystem = {
        system = "x86_64-linux";
        gcc = {
          arch = "znver4";
          tune = "znver4";
        };
      };

      # localSystem covers Nixpkgs' C-family compiler wrappers. Extend the same
      # host boundary to standard Rust and Go builders without overriding an
      # explicit package target.
      muscleNativeOverlay =
        _final: prev:
        let
          inherit (inputs.nixpkgs) lib;
          isNativeHost =
            prev.stdenv.hostPlatform.system == "x86_64-linux"
            && (prev.stdenv.hostPlatform.gcc.arch or null) == "znver4";
          mapBuilderArgs =
            transform: args:
            if builtins.isFunction args then finalAttrs: transform (args finalAttrs) else transform args;
          # Nixpkgs builders are callable attribute sets. Preserve their
          # `.override` interface because CUDA and other package families replace
          # builder dependencies such as stdenv before invoking them.
          wrapBuilder =
            transform: builder:
            builder
            // {
              __functor = _self: args: builder (mapBuilderArgs transform args);
              override = overrides: wrapBuilder transform (builder.override overrides);
            };
          addRustTarget =
            args:
            let
              env = args.env or { };
              nixRustFlags = toString (env.NIX_RUSTFLAGS or "");
              maySetTarget = !(env ? RUSTFLAGS) && !(args ? RUSTFLAGS) && !(args ? NIX_RUSTFLAGS);
            in
            args
            // {
              env =
                env
                // lib.optionalAttrs maySetTarget {
                  NIX_RUSTFLAGS =
                    nixRustFlags + lib.optionalString (!lib.hasInfix "target-cpu" nixRustFlags) " -C target-cpu=znver4";
                };
            };
          addGoTarget =
            args:
            let
              env = args.env or { };
            in
            args
            // {
              env = env // lib.optionalAttrs (!(env ? GOAMD64) && !(args ? GOAMD64)) { GOAMD64 = "v4"; };
            };
        in
        lib.optionalAttrs isNativeHost {
          rustPlatform = prev.rustPlatform // {
            buildRustPackage = wrapBuilder addRustTarget prev.rustPlatform.buildRustPackage;
          };
          buildGoModule = wrapBuilder addGoTarget prev.buildGoModule;
        };

      # Compatibility policy is separate from channel promotion. Every excluded
      # package stays on the exact primary Nixpkgs revision; no failure silently
      # changes its channel or version.
      muscleCompatibilityOverlay =
        _final: prev:
        let
          inherit (inputs.nixpkgs) lib;
          isNativeHost =
            prev.stdenv.hostPlatform.system == "x86_64-linux"
            && (prev.stdenv.hostPlatform.gcc.arch or null) == "znver4";
          genericPrimary = inputs.nixpkgs.legacyPackages.x86_64-linux;
          # Keep Python packages in one coherent package set while excluding only
          # their own C/Rust objects, avoiding duplicate module closures.
          withoutNativeCodegen =
            package:
            package.overrideAttrs (old: {
              env = (old.env or { }) // {
                NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -march=x86-64 -mtune=generic";
                NIX_RUSTFLAGS = toString (old.env.NIX_RUSTFLAGS or "") + " -C target-cpu=x86-64";
              };
            });
        in
        lib.optionalAttrs isNativeHost {
          # SciPy's native objects produce architecture-dependent optimizer,
          # signal, and finite-difference results; only one scalar/vector
          # comparison then needs its mathematically realistic 1e-12 tolerance.
          # Cryptography's 4 TiB Argon2 failure test assumes Linux rejects virtual
          # allocation, but permissive overcommit can OOM-kill the worker instead.
          # Bound its address space so the MemoryError path remains tested. No
          # test is skipped.
          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (
              _pythonFinal: pythonPrev:
              lib.optionalAttrs (pythonPrev.python.pythonVersion == "3.13") {
                cryptography = pythonPrev.cryptography.overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace tests/hazmat/primitives/test_argon2.py \
                      --replace-fail $'import os\nimport sys' $'import os\nimport resource\nimport sys' \
                      --replace-fail $'        with pytest.raises(MemoryError):\n            argon2.derive(b"password")' \
                        $'        old_limit = resource.getrlimit(resource.RLIMIT_AS)\n        soft_limit = 1 << 40 if old_limit[0] == resource.RLIM_INFINITY else min(1 << 40, old_limit[0])\n        resource.setrlimit(resource.RLIMIT_AS, (soft_limit, old_limit[1]))\n        try:\n            with pytest.raises(MemoryError):\n                argon2.derive(b"password")\n        finally:\n            resource.setrlimit(resource.RLIMIT_AS, old_limit)'
                  '';
                });
                scipy = (withoutNativeCodegen pythonPrev.scipy).overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    substituteInPlace scipy/differentiate/tests/test_differentiate.py \
                      --replace-fail "xp_assert_close(res.df[i, :], ref.df, rtol=1e-14)" \
                      "xp_assert_close(res.df[i, :], ref.df, rtol=1e-12)"
                  '';
                });
              }
            )
          ];

          # Cryptonite's Ed448 KAT fails under host code generation. Keep the
          # signed-cache client closure from generic primary Nixpkgs.
          inherit (genericPrimary) cachix;

          # Runtime-dispatched libraries and architecture-neutral headers gain no
          # useful installed payload from a host target. The generic closure also
          # lets Valgrind execute a supported loader; consumers still compile the
          # headers with the native package set.
          inherit (genericPrimary)
            openssl
            rapidjson
            simde
            xsimd
            ;

          # These unchanged primary-channel recipes fail architecture-sensitive
          # tests or diagnostics. Exclude their complete closures so tests and
          # memory-safety diagnostics remain authoritative.
          inherit (genericPrimary)
            assimp
            libtpms
            openldap
            swtpm
            ;
        };

      # Snowfall preconstructs nixpkgs and injects it through `nixpkgs.pkgs`,
      # which makes a host module's `nixpkgs.hostPlatform` ineffective. Muscle
      # is the intentional package-set boundary: construct both stable and
      # unstable with the same Zen 4 policy so promoted packages cannot bypass
      # native compilation. Nix requires a gccarch-znver4-capable builder.
      muscleNixosBuilder =
        args:
        let
          channel = args.specialArgs.channel;
          channelConfig = channel.config // {
            allowUnfree = true;
            cudaSupport = true;
          };
          muscleUnstablePkgs = import inputs.unstable {
            localSystem = muscleLocalSystem;
            overlays = [ muscleNativeOverlay ];
            config = channelConfig;
          };
          musclePkgs = import channel.path {
            localSystem = muscleLocalSystem;
            overlays = [
              (_final: prev: {
                landNativeChannels = (prev.landNativeChannels or { }) // {
                  unstable = muscleUnstablePkgs;
                };
              })
              muscleNativeOverlay
            ]
            ++ channel.overlays
            ++ [ muscleCompatibilityOverlay ];
            config = channelConfig;
          };
        in
        inputs.nixpkgs.lib.nixosSystem (
          args
          // {
            specialArgs = args.specialArgs // {
              format = "linux";
            };
            modules = args.modules ++ [
              inputs.snowfall-lib.nixosModules.user
              ({ lib, ... }: {
                nixpkgs.pkgs = lib.mkForce musclePkgs;
              })
            ];
          }
        );

      # Generate base outputs
      baseOutputs = lib.mkFlake {
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
          # Expose llm-agents' own pinned, cache-backed package set without
          # rebuilding it against stable nixpkgs. The namespace also makes the
          # package provenance explicit at every call site.
          (final: _prev: {
            llm-agents = llm-agents.packages.${final.stdenv.hostPlatform.system};
          })
          # ariang's package-lock.json is v1 with a git URL for
          # angular-input-dropdown. npm ci in newer npm fails validating
          # sync. Wrap npm to substitute `npm ci` with `npm install`.
          # Drop when nixpkgs fixes upstream ariang.
          (final: prev: {
            ariang = prev.ariang.overrideAttrs (old: {
              prePatch = (old.prePatch or "") + ''
                mkdir -p .npm-wrapper
                cat > .npm-wrapper/npm <<'WRAPPER'
                #!/bin/sh
                if [ "$1" = "ci" ]; then
                  shift
                  exec ${final.nodejs}/bin/npm install --no-audit --no-fund "$@"
                fi
                exec ${final.nodejs}/bin/npm "$@"
                WRAPPER
                chmod +x .npm-wrapper/npm
                export PATH="$PWD/.npm-wrapper:$PATH"
              '';
            });
          })
        ];

        systems = {
          modules = {
            darwin = with inputs; [
              nix-homebrew.darwinModules.nix-homebrew
            ];

            nixos = with inputs; [
              disko.nixosModules.disko
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

            # Vicinae's input-server wrapper (global hotkey capture) and
            # lanzaboote for UEFI Secure Boot with sbctl-managed keys.
            muscle = {
              builder = muscleNixosBuilder;
              modules = with inputs; [
                vicinae.nixosModules.default
                lanzaboote.nixosModules.lanzaboote
              ];
            };
          };
        };

        homes.users."mykhailo@muscle".modules = with inputs; [
          vicinae.homeManagerModules.default
          voxtype.homeManagerModules.default
        ];
      };

      getSystemPackages =
        system:
        if builtins.hasAttr "packages" baseOutputs && builtins.hasAttr system baseOutputs.packages then
          lib.filterAttrs (_: package: lib.isDerivation package) baseOutputs.packages.${system}
        else
          { };

      namespacePackageChecks = lib.genAttrs supportedSystems (
        system:
        lib.mapAttrs' (name: package: lib.nameValuePair "package-${name}" package) (
          getSystemPackages system
        )
      );

      nativeOptimizationPolicyCheck =
        let
          muscle = baseOutputs.nixosConfigurations.muscle.pkgs;
          ghost = baseOutputs.nixosConfigurations.ghost.pkgs;
          generic = inputs.nixpkgs.legacyPackages.x86_64-linux;
          inspectEnv =
            package:
            (package.overrideAttrs (old: {
              passthru = (old.passthru or { }) // {
                nativePolicyEnv = old.env or { };
              };
            })).nativePolicyEnv;
          sameChannelExceptions = [
            "assimp"
            "cachix"
            "libtpms"
            "openldap"
            "openssl"
            "rapidjson"
            "simde"
            "swtpm"
            "xsimd"
          ];
        in
        assert lib.assertMsg (
          muscle.stdenv.hostPlatform.gcc.arch == "znver4"
          && muscle.landNativeChannels.unstable.stdenv.hostPlatform.gcc.arch == "znver4"
        ) "Muscle's primary and unstable package sets must both target znver4";
        assert lib.assertMsg (
          (inspectEnv muscle.ripgrep).NIX_RUSTFLAGS == " -C target-cpu=znver4"
          && (inspectEnv muscle.git-lfs).GOAMD64 == "v4"
        ) "Muscle's standard Rust and Go builders must retain native targets";
        assert lib.assertMsg (
          !lib.hasInfix "znver4" (toString ((inspectEnv muscle.pkgsi686Linux.ripgrep).NIX_RUSTFLAGS or ""))
          && ((inspectEnv muscle.pkgsi686Linux.git-lfs).GOAMD64 or null) != "v4"
          && (muscle.pkgsi686Linux.stdenv.hostPlatform.gcc.arch or null) != "znver4"
        ) "Muscle's native targets must not leak into the i686 package splice";
        assert lib.assertMsg (
          !(ghost ? landNativeChannels)
          && (ghost.stdenv.hostPlatform.gcc.arch or null) != "znver4"
          && ((inspectEnv ghost.ripgrep).NIX_RUSTFLAGS or null) == null
          && ((inspectEnv ghost.git-lfs).GOAMD64 or null) == null
        ) "Muscle's native targets must not leak into another x86_64 host";
        assert lib.assertMsg (lib.all (
          name: muscle.${name}.drvPath == generic.${name}.drvPath
        ) sameChannelExceptions) "Native compatibility exceptions must stay on primary Nixpkgs";
        assert lib.assertMsg (
          muscle.cudaPackages.flags.cudaCapabilities == [ "8.9" ]
          && (inspectEnv muscle.ollama-cuda).GOAMD64 == "v4"
        ) "Muscle's CUDA and Ollama builds must target Ada and GOAMD64 v4";
        generic.runCommand "native-optimization-policy" { } ''
          touch "$out"
        '';

      nativePolicyChecks.x86_64-linux.native-optimization-policy = nativeOptimizationPolicyCheck;

      outputs = baseOutputs // {
        checks = lib.recursiveUpdate (baseOutputs.checks or { }) (
          lib.recursiveUpdate namespacePackageChecks nativePolicyChecks
        );
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
