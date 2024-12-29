{ pkgs, ... }:

{
  # TODO: Add qflipper to systemPackages instead of homebrew
  # Currently marked as broken on aarch64-darwin
  # environment.systemPackages = [
  #   pkgs.qflipper
  # ];

  imports = [
    ../homebrew.nix
  ];

  homebrew.casks = [
    "qflipper"
  ];
}
