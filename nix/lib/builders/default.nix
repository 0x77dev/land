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

  # Helper to get the first admin user for SSH
  getAdminUser =
    config:
    let
      users = config.config.snowfallorg.users or { };
      adminUsers = lib.filterAttrs (_name: user: user.admin or false) users;
      adminNames = lib.attrNames adminUsers;
    in
    if adminNames != [ ] then lib.head adminNames else null;

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
  mkBuildMachine =
    _: config:
    let
      inherit (config.config.networking) fqdn;
      inherit (config.config.modules.builders) speedFactor;
      sshUser = getAdminUser config;
      system = getSystem config;
      maxJobs = getMaxJobs config;
      speedFactor = config.config.modules.builders.speedFactor or 1;
      supportedFeatures = getSupportedFeatures config;
    in
    lib.optionalAttrs (sshUser != null) {
      hostName = fqdn;
      inherit sshUser maxJobs speedFactor;
      protocol = "ssh-ng";
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

      # Filter out empty entries (where sshUser was null)
      validBuildMachines = lib.filter (m: m != { }) buildMachinesList;
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
      nix.buildMachines = remoteBuildMachines;

      # Configure SSH to accept new host keys for builders
      programs.ssh.extraConfig = lib.mkAfter ''
        Host ${lib.concatStringsSep " " builderHosts}
          StrictHostKeyChecking accept-new
      '';
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
