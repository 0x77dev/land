{
  lib,
  inputs,
  ...
}:
{
  # Automatically generate deploy-rs configuration from Snowfall Lib outputs
  # This eliminates manual configuration for each system
  mkDeployNodes =
    {
      darwinConfigurations ? { },
      nixosConfigurations ? { },
      # Default SSH user per platform
      defaultDarwinSshUser ? "0x77",
      defaultNixosSshUser ? "mykhailo",
      # Hostname suffix for NixOS systems
      hostnameSuffix ? ".0x77.computer",
    }:
    let
      # Helper to determine system architecture from configuration
      getSystem =
        config:
        if config.pkgs.stdenv.isDarwin then
          config.pkgs.stdenv.hostPlatform.system
        else
          config.config.nixpkgs.hostPlatform.system or config.pkgs.stdenv.hostPlatform.system;

      # Create a deploy-rs node for a Darwin system
      mkDarwinNode =
        name: config:
        let
          system = getSystem config;
        in
        {
          hostname = name;
          profiles.system = {
            user = "root";
            sshUser = defaultDarwinSshUser;
            path = inputs.deploy-rs.lib.${system}.activate.darwin config;
            interactiveSudo = false;
          };
        };

      # Create a deploy-rs node for a NixOS system
      mkNixosNode =
        name: config:
        let
          system = getSystem config;
          # Use hostname as-is if it contains a dot (FQDN), otherwise add suffix
          hostname = if lib.hasInfix "." name then name else "${name}${hostnameSuffix}";
        in
        {
          inherit hostname;
          profiles.system = {
            user = "root";
            sshUser = defaultNixosSshUser;
            path = inputs.deploy-rs.lib.${system}.activate.nixos config;
            interactiveSudo = false;
          };
        };

      # Generate nodes for all Darwin systems
      darwinNodes = lib.mapAttrs mkDarwinNode darwinConfigurations;

      # Generate nodes for all NixOS systems
      nixosNodes = lib.mapAttrs mkNixosNode nixosConfigurations;
    in
    # Merge both sets of nodes
    darwinNodes // nixosNodes;
}
