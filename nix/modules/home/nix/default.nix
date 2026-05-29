{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.nix;
  flakeInputChannels = lib.mapAttrs (_name: input: input.outPath) (
    lib.filterAttrs (_name: input: input ? outPath) (removeAttrs inputs [ "self" ])
  );
in
{
  options.modules.home.nix = {
    enable = mkEnableOption "nix";
  };

  config = mkMerge [
    {
      # Register every flake input as a Home Manager channel so legacy
      # channel-style lookups resolve to this flake's locked revisions.
      nix.channels = mkDefault flakeInputChannels;
    }

    (mkIf cfg.enable {
      home.packages = with pkgs; [
        nix-output-monitor
        cachix
      ];
    })
  ];
}
