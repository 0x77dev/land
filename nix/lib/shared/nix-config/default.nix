{ inputs, ... }:
{ lib, ... }:
let
  substituters = [
    "https://cache.nixos.org"
    "https://land.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixos-raspberrypi.cachix.org"
    # NVIDIA-authorized pre-built CUDA binaries for aarch64-linux (DGX Spark).
    # https://flox.dev
    "https://cache.flox.dev"
  ];

  # Every flake input that is itself a flake (excluding `self`). These are
  # pinned into both the flake registry and the legacy `NIX_PATH` so that
  # `nix shell nixpkgs#...` and channel-style `<nixpkgs>` lookups resolve to
  # the exact revisions locked by this flake.
  flakeInputs = lib.filterAttrs (_name: input: input ? outputs) (removeAttrs inputs [ "self" ]);
in
{
  registry = lib.mapAttrs (_name: flake: { inherit flake; }) flakeInputs;

  # Back legacy channels (`<nixpkgs>`, `<unstable>`, ...) with the same pinned
  # inputs, replacing the mutable system/user channel state.
  nixPath = lib.mapAttrsToList (name: input: "${name}=${input}") flakeInputs;

  settings = {
    accept-flake-config = true;
    builders-use-substitutes = true;
    experimental-features = [
      "nix-command"
      "flakes"
      "recursive-nix"
    ];

    keep-derivations = true;
    keep-outputs = true;
    log-lines = 50;
    inherit substituters;
    trusted-substituters = substituters;
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "land.cachix.org-1:9KPti8Xi0UJ7eQof7b8VUzSYU5piFy6WVQ8MDTLOqEA="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
    trusted-users = [
      "root"
      "@wheel"
      "@admin"
    ];

    max-jobs = "auto";
    cores = 0;
    # mkDefault so a host with an overlay store (vasyl) can disarm the in-daemon
    # auto-GC by setting these to 0; every other host keeps these values.
    min-free = lib.mkDefault 1073741824; # 1 GiB
    max-free = lib.mkDefault 4294967296; # 4 GiB
    connect-timeout = 5;
    download-speed = 0;
    narinfo-cache-negative-ttl = 0;
    sandbox = true;
    use-xdg-base-directories = true;
    warn-dirty = true;
  };

  gc = {
    automatic = lib.mkDefault true;
    options = "--delete-older-than 14d";
  };

  optimise.automatic = lib.mkDefault true;

  distributedBuilds = lib.mkDefault false;
}
