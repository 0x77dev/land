{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.filesystem.zfs;

  # Calculate the latest ZFS-compatible kernel
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;

  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  options.modules.filesystem.zfs = {
    enable = lib.mkEnableOption "ZFS Filesystem Support";

    useLatestKernel = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the latest ZFS-compatible kernel available.
        Note: This may cause the kernel version to go backwards as kernels become EOL.
      '';
    };

    useUnstable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the unstable/pre-release version of ZFS (zfs_unstable).
        Warning: This is experimental and may have bugs that cause data loss.
      '';
    };

    extraPools = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "zpool"
        "tank"
      ];
      description = ''
        Additional ZFS pools to import on boot.
      '';
    };

    devNodes = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "/dev/disk/by-id";
      example = "/dev/disk/by-partuuid";
      description = ''
        Device node path for ZFS pool imports.
        Set to /dev/disk/by-id for pools created with disk IDs,
        or /dev/disk/by-partuuid for pools with partition UUIDs.
      '';
    };

    arcMaxSizeGB = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 12;
      description = ''
        Maximum size of the ZFS Adaptive Replacement Cache (ARC) in gigabytes.
        If null, ZFS will use its default heuristics.
      '';
    };

    autoScrub = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable automatic scrubbing of ZFS pools.
        '';
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        example = "monthly";
        description = ''
          Systemd calendar expression for scrub interval.
        '';
      };

      pools = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "zpool" ];
        description = ''
          List of pools to scrub. Empty means all pools.
        '';
      };
    };

    autoTrim = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable automatic TRIM on ZFS pools.
        '';
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        example = "monthly";
        description = ''
          Systemd calendar expression for trim interval.
        '';
      };
    };

    autoSnapshot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable automatic snapshots of ZFS datasets.
        '';
      };

      flags = lib.mkOption {
        type = lib.types.str;
        default = "-k -p --utc";
        description = ''
          Flags to pass to the zfs-auto-snapshot command.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Boot configuration
    boot = {
      # Select kernel version
      kernelPackages = lib.mkIf cfg.useLatestKernel latestKernelPackage;

      # Core ZFS configuration
      supportedFilesystems = [ "zfs" ];

      # ARC size tuning
      kernelParams = lib.mkIf (cfg.arcMaxSizeGB != null) [
        "zfs.zfs_arc_max=${toString (cfg.arcMaxSizeGB * 1024 * 1024 * 1024)}"
      ];

      # ZFS-specific configuration
      zfs = {
        # ZFS package selection
        package = lib.mkIf cfg.useUnstable pkgs.zfs_unstable;
        forceImportRoot = lib.mkDefault false;
        inherit (cfg) extraPools;
        devNodes = lib.mkIf (cfg.devNodes != null) cfg.devNodes;
      };
    };

    # Enable ZFS services
    services.zfs = {
      autoScrub = {
        inherit (cfg.autoScrub) enable interval pools;
      };

      trim = {
        inherit (cfg.autoTrim) enable interval;
      };

      autoSnapshot = {
        inherit (cfg.autoSnapshot) enable flags;
      };
    };

    # Networking hostId is required for ZFS
    assertions = [
      {
        assertion = config.networking.hostId != null && config.networking.hostId != "";
        message = "ZFS requires networking.hostId to be set";
      }
    ];
  };
}
