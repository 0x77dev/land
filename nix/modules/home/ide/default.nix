{
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cursorPackage = if isLinux then pkgs.code-cursor-fhs else pkgs.code-cursor;
in
{
  home.packages = with pkgs; [
    # Code editor
    cursorPackage
  ];

  # Configure Cursor (VSCode-based editor)
  programs.vscode = {
    enable = true;
    package = cursorPackage;

    # FHS wrapper on Linux for better extension support
    # Native macOS app on Darwin
  };
}
