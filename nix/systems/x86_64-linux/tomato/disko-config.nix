{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_OM3PGP41024P-A0_50026B72836AD3FC";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              # 1G: lanzaboote-signed UKIs are ~100-170MB each; 8 generations
              # won't fit in 512M. Kingston is 1TB with ESP the only partition.
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # Rest of Kingston left unallocated — /nix lives on the mirror so
            # a single-disk death can't brick the boot path.
          };
        };
      };
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117852T";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot1";
                # Create-time recovery key (nixos-anywhere
                # --disk-encryption-keys places it); fed to luksFormat.
                passwordFile = "/tmp/cryptsystem.key";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };
      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117856R";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot2";
                passwordFile = "/tmp/cryptsystem.key";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };
      };
    };
    zpool = {
      # Mirrored data pool: tolerates one Samsung 4TB death, mirror-fast reads
      # for streaming. ~4 TB usable.
      zroot = {
        type = "zpool";
        mode = "mirror";
        options = {
          cachefile = "none";
          ashift = "12";
        };
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "false";
        };
        mountpoint = "/";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";

        datasets = {
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
          };
          var = {
            type = "zfs_fs";
            mountpoint = "/var";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
          data = {
            type = "zfs_fs";
            mountpoint = "/data";
          };
          "data/media" = {
            type = "zfs_fs";
            mountpoint = "/data/media";
            options."com.sun:auto-snapshot" = "true";
          };
          "data/documents" = {
            type = "zfs_fs";
            mountpoint = "/data/documents";
            options."com.sun:auto-snapshot" = "true";
          };
          # Per-container state datasets use independent auto-snapshots so
          # media and tsidp state can roll back without pulling all of /var.
          containers = {
            type = "zfs_fs";
            mountpoint = "/var/lib/nixos-containers";
          };
          "containers/media" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/nixos-containers/media";
            options."com.sun:auto-snapshot" = "true";
          };
          "containers/tsidp" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/nixos-containers/tsidp";
            options."com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
}
