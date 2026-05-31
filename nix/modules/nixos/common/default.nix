{
  config,
  pkgs,
  lib,
  system,
  ...
}:
with lib;
{
  # Common System Configuration
  time.timeZone = mkDefault "America/New_York";
  i18n.defaultLocale = mkDefault "en_US.UTF-8";

  # Shell
  programs.fish.enable = true;
  programs.helium.enable = mkDefault config.modules.graphical.enable;

  # Nixpkgs
  nixpkgs.hostPlatform = mkDefault system;
  nixpkgs.config.allowUnfree = true;

  # Latest mainline kernel by default. Hardware/ZFS constraints override this
  # (muscle → CachyOS, spark → vendored NVIDIA kernel, timey → pinned RPi,
  # ghost/tomato → latest ZFS-compatible). CPU vulnerability mitigations are
  # deliberately left at the kernel's per-CPU defaults: enabled and correct,
  # with no global `mitigations=off` (which would trade security for perf).
  boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;
  boot.zfs.forceImportRoot = mkDefault false;

  # Common Packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    btop
    ncdu
    nettools
    hwloc
    bind
  ];
}
