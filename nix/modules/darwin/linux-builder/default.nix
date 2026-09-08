{ lib, ... }:
{
  # Keep the upstream builder package unmodified so cache substitution can
  # bootstrap it before the Linux VM exists.
  nix.linux-builder.enable = lib.mkDefault false;
}
