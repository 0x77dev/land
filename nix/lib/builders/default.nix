{
  lib,
  ...
}:
let
  # Helper to get system architecture from configuration
  getSystem =
    config:
    if config.pkgs.stdenv.isDarwin then
      config.pkgs.stdenv.hostPlatform.system
    else
      config.config.nixpkgs.hostPlatform.system or config.pkgs.stdenv.hostPlatform.system;

  # Helper to determine if a system is a builder
  isBuilder = config: config.config.modules.builders.enable or false;

  # Helper to determine max jobs
  getMaxJobs =
    config:
    let
      configured = config.config.modules.builders.maxJobs or null;
    in
    if configured != null then configured else 20;

  # Helper to get supported features
  getSupportedFeatures =
    config:
    if config.pkgs.stdenv.isLinux then
      [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ]
    else
      [
        "benchmark"
        "big-parallel"
      ];

  # Create a build machine entry from a configuration
  # MODIFIED: Now uses nixbuilder user and SSH key
  mkBuildMachine =
    _: config:
    let
      inherit (config.config.networking) fqdn;
      system = getSystem config;
      maxJobs = getMaxJobs config;
      speedFactor = config.config.modules.builders.speedFactor or 1;
      supportedFeatures = getSupportedFeatures config;
    in
    {
      hostName = fqdn;
      sshUser = "nixbuilder"; # Changed from getAdminUser
      sshKey = "/run/secrets/builders/ssh_private_key"; # Added
      protocol = "ssh-ng"; # Use modern protocol
      inherit maxJobs speedFactor;
      systems = [ system ];
      inherit supportedFeatures;
    };
in
{
  # Generate a module that configures distributed build machines
  # This is called after outputs are generated to have access to all configurations
  mkBuildersModule =
    {
      darwinConfigurations ? { },
      nixosConfigurations ? { },
    }:
    let
      # Collect all configurations
      allConfigs = darwinConfigurations // nixosConfigurations;

      # Filter to only builders
      builderConfigs = lib.filterAttrs (_name: isBuilder) allConfigs;

      # Generate build machine entries
      buildMachinesList = lib.mapAttrsToList mkBuildMachine builderConfigs;

      # All build machines are now valid (no null sshUser checks needed)
      validBuildMachines = buildMachinesList;
    in
    # Return a module that can be applied to all systems
    {
      config,
      lib,
      ...
    }:
    let
      # Filter out the current host
      currentHostname = config.networking.hostName;
      remoteBuildMachines = lib.filter (m: !lib.hasInfix currentHostname m.hostName) validBuildMachines;

      # Get list of builder hostnames
      builderHosts = map (m: m.hostName) remoteBuildMachines;
    in
    {
      # Enable distributed builds if there are remote builders
      nix.distributedBuilds = lib.mkIf (remoteBuildMachines != [ ]) true;

      # Configure build machines
      nix.buildMachines = remoteBuildMachines;

      # Configure SSH to accept new host keys for builders
      # Use Match User to only apply to nixbuilder connections
      programs.ssh.extraConfig = lib.mkIf (remoteBuildMachines != [ ]) (
        lib.mkAfter ''
          Match User nixbuilder Host ${lib.concatStringsSep "," builderHosts}
            StrictHostKeyChecking accept-new
            IdentityFile /run/secrets/builders/ssh_private_key
        ''
      );
    };

  # Create a module that will be included in all systems
  # This module accesses configurations through specialArgs
  autoBuilders =
    {
      config,
      lib,
      allConfigurations ? { },
      ...
    }:
    let
      # Filter to only builders
      builderConfigs = lib.filterAttrs (
        _name: cfg: (cfg.config.modules.builders.enable or false)
      ) allConfigurations;

      # Generate build machine entries
      buildMachinesList = lib.mapAttrsToList mkBuildMachine builderConfigs;

      # Filter out empty entries and current host
      currentHostname = config.networking.hostName;
      remoteBuildMachines = lib.filter (
        m: m != { } && !lib.hasInfix currentHostname m.hostName
      ) buildMachinesList;
    in
    {
      nix.buildMachines = remoteBuildMachines;
    };
}
