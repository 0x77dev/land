{
  pkgs,
  lib,
  system,
  ...
}:
{
  # Common System Configuration
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Shell
  programs.fish.enable = true;

  # Nixpkgs
  nixpkgs.hostPlatform = lib.mkDefault system;
  nixpkgs.config.allowUnfree = true;

  # Latest mainline kernel by default. Hardware/ZFS constraints override this
  # (muscle → CachyOS, spark → vendored NVIDIA kernel, timey → pinned RPi,
  # ghost/tomato → latest ZFS-compatible). CPU vulnerability mitigations are
  # deliberately left at the kernel's per-CPU defaults: enabled and correct,
  # with no global `mitigations=off` (which would trade security for perf).
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

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
