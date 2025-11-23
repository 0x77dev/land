{ lib, pkgs, ... }:
let
  inherit (lib)
    attrByPath
    mkDefault
    optional
    unique
    ;

  hostIsAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
  linuxSystems = unique ([ "x86_64-linux" ] ++ optional hostIsAarch64 "aarch64-linux");
  emulatedSystems = if hostIsAarch64 then [ "x86_64-linux" ] else [ "aarch64-linux" ];

  rawHostCores = attrByPath [ "parsed" "cpu" "cores" ] 6 pkgs.stdenv.hostPlatform;
  defaultCores =
    if rawHostCores < 2 then
      2
    else if rawHostCores > 8 then
      8
    else
      rawHostCores;

  defaultMemoryMiB = 8192;
  defaultDiskMiB = 120 * 1024;
in
{
  nix.linux-builder = {
    enable = mkDefault true;
    systems = mkDefault linuxSystems;
    supportedFeatures = mkDefault [
      "kvm"
      "benchmark"
      "big-parallel"
    ];
    maxJobs = mkDefault defaultCores;

    config = _: {
      # NOTE: requires distributed build with aarch64-linux builders
      nix.settings = {
        auto-optimise-store = true;
        builders-use-substitutes = true;
        extra-platforms = linuxSystems;
        keep-derivations = true;
        keep-outputs = true;
        log-lines = 50;
        cores = 0;
      };

      boot.binfmt.emulatedSystems = emulatedSystems;

      virtualisation = {
        cores = mkDefault defaultCores;
        memorySize = mkDefault defaultMemoryMiB;
        diskSize = mkDefault defaultDiskMiB;
        graphics = mkDefault false;
      };
    };
  };
}
