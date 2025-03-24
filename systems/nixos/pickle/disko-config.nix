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
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
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
                type = "zfs";
                pool = "zroot";
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
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "";
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
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
          var = {
            type = "zfs_fs";
            mountpoint = "/var";
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
          # K3s dataset
          k3s = {
            type = "zfs_fs";
            mountpoint = "/var/lib/rancher/k3s";
            options."com.sun:auto-snapshot" = "true";
          };
          # Longhorn dataset for storage
          longhorn = {
            type = "zfs_fs";
            mountpoint = "/var/lib/longhorn";
            options."com.sun:auto-snapshot" = "true";
          };
        };
      };
    };
  };
}
