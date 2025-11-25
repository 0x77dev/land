{
  config,
  lib,
  inputs,
  ...
}:
{
  options.modules.builders = {
    enable = lib.mkEnableOption "Make this system available as a remote builder";

    maxJobs = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Max parallel jobs (auto-detected if null)";
    };

    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Speed factor relative to other builders";
    };
  };

  # Configure private key for systems that use remote builders
  config = lib.mkIf (config.nix.buildMachines != [ ]) {
    sops.secrets."builders/ssh_private_key" = {
      mode = "0400"; # SSH requires strict permissions
      owner = "root";
      key = "ssh/private_key";
      sopsFile = inputs.self + "/nix/lib/builders/secrets.yaml";
    };
  };
}
