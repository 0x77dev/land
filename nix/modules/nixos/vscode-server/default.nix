{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.vscode-server;
in
{
  options.modules.vscode-server.enable = lib.mkEnableOption "VS Code Remote server runtime compatibility";

  config = lib.mkIf cfg.enable {
    # VS Code Remote installs prebuilt ELF binaries in the user's home. Let
    # nix-ld provide their interpreter and native extension dependencies
    # without rewriting mutable server installations.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        icu
        krb5
        libunwind
        lttng-ust
      ];
    };
  };
}
