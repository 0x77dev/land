{ lib, ... }:
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
}
