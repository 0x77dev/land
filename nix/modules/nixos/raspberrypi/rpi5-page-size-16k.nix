{ lib, inputs, ... }:
{
  # Optimizations or fixes for systems running
  # rpi5 (bcm2712-configured) Linux kernel

  nixpkgs.overlays = lib.mkBefore [
    (import "${inputs.nixos-raspberrypi}/overlays/jemalloc-page-size-16k.nix")
  ];
}
