# VS Code Server module for NixOS
# Based on https://github.com/nix-community/nixos-vscode-server

{ config, lib, pkgs, ... }:

with lib;

{
  options.modules.vscode-server = {
    enable = mkEnableOption "VS Code Server with optimal settings";

    enableFHS = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable FHS-compatible environment for VS Code Server.
        This helps binaries supplied by extensions work without patching.
      '';
    };

    nodejsPackage = mkOption {
      type = types.package;
      default = pkgs.nodejs_20;
      description = ''
        The Node.js package to use for VS Code Server.
        VS Code Server will use this instead of downloading its own version.
      '';
    };

    extraRuntimeDependencies = mkOption {
      type = types.functionTo (types.listOf types.package);
      default = pkgs: with pkgs; [
        # Common dependencies for development
        curl
        wget
        git
        gnumake
        gcc
        openssl
        # Add more common dependencies as needed
      ];
      description = ''
        Extra runtime dependencies for the FHS environment.
        These packages will be available to VS Code Server extensions.
      '';
    };
  };

  config = mkIf config.modules.vscode-server.enable {
    services.vscode-server = {
      enable = true;
      enableFHS = config.modules.vscode-server.enableFHS;
      nodejsPackage = config.modules.vscode-server.nodejsPackage;
      extraRuntimeDependencies = config.modules.vscode-server.extraRuntimeDependencies;
    };

    # Ensure SSH server is enabled for remote connections
    services.openssh.enable = mkDefault true;

    # Add a note to remind users to enable the user service
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "setup-vscode-server" ''
        echo "Setting up VS Code Server for current user..."
        systemctl --user enable auto-fix-vscode-server.service
        systemctl --user start auto-fix-vscode-server.service
        echo "VS Code Server has been set up for $(whoami)."
        echo "You can now connect to this machine using VS Code's Remote SSH extension."
      '')
    ];
  };
}
