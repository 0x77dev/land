{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  hostIsX86_64 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
lib.mkIf hostIsX86_64 {
  boot.binfmt.emulatedSystems = mkDefault [ "aarch64-linux" ];

  environment.systemPackages = mkIf (config.boot.binfmt.emulatedSystems != [ ]) (with pkgs; [ qemu ]);

  nix.settings.extra-platforms = mkDefault [ "aarch64-linux" ];
}
