_:
{ lib, ... }:
let
  substituters = [
    "https://cache.nixos.org"
    "https://land.cachix.org"
    "https://nix-community.cachix.org"
    "https://nixos-raspberrypi.cachix.org"
  ];
in
{
  settings = {
    accept-flake-config = true;
    builders-use-substitutes = true;
    experimental-features = [
      "nix-command"
      "flakes"
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
    ];
    trusted-users = [
      "root"
      "@wheel"
      "@admin"
    ];

    max-jobs = "auto";
    cores = 0;
    min-free = 1073741824; # 1 GiB
    max-free = 4294967296; # 4 GiB
    connect-timeout = 5;
    download-speed = 0;
    narinfo-cache-negative-ttl = 0;
    sandbox = true;
    use-xdg-base-directories = true;
    warn-dirty = true;
  };

  gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  optimise.automatic = true;

  distributedBuilds = lib.mkDefault true;
}
