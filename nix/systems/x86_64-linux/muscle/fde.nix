# Full-disk-encryption target for the reinstall. NOT imported yet — swap
# the `./disko-config.nix` import for `./fde.nix` when executing.
#
# Layout: two disks, both LUKS2 under TPM2 auto-unlock.
#   Crucial T500 2TB   -> system: btrfs (subvolumes, zstd, autoscrub)
#   Samsung PM9A3 7.6TB -> /home (XFS) + /var/lib/docker (XFS, pquota)
#
# Runbook:
#   1. Swap the import in default.nix: ./disko-config.nix -> ./fde.nix.
#   2. `nixos-anywhere --flake .#muscle root@muscle` (disko formats and
#      prompts for LUKS passphrases; the Windows install on the T500 dies).
#   3. First boot: enroll both volumes into the TPM (PCR 7 is stable with
#      Secure Boot + measured UKIs):
#        for p in /dev/disk/by-id/nvme-CT2000T500SSD8_241047BE2CB4-part2 \
#                 /dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716-part1; do
#          systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$p"
#        done
#   4. Restore anything wanted from the old root (it lived on the PM9A3,
#      now reformatted — hence do step 0: copy anything precious first).
{ lib, ... }:
{
  # systemd in the initrd: required for TPM2 LUKS unlock.
  boot.initrd.systemd.enable = true;

  # Swap moves to a btrfs-native swapfile subvolume (below).
  swapDevices = lib.mkForce [ ];

  # Btrfs upkeep: monthly scrub for checksummed self-healing, weekly TRIM
  # (allowDiscards is set on both LUKS volumes).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  services.fstrim.enable = true;

  disko.devices.disk = {
    system = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-CT2000T500SSD8_241047BE2CB4";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptsystem";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "128G";
                  };
                };
              };
            };
          };
        };
      };
    };

    data = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716";
      content = {
        type = "gpt";
        partitions = {
          # GPUDirect Storage scratch: cuFile's true DMA path (NVMe -> GPU)
          # requires XFS/ext4 with O_DIRECT and *no* dm-crypt underneath, so
          # this one partition stays unencrypted. Datasets/model weights
          # only — nothing confidential.
          scratch = {
            size = "1T";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/scratch";
              mountOptions = [ "noatime" ];
            };
          };
          data = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptdata";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true;
              };
              content = {
                type = "lvm_pv";
                vg = "data";
              };
            };
          };
        };
      };
    };
  };

  # One LUKS layer, two XFS volumes: /home gets the bulk, docker gets a
  # dedicated XFS volume with project quotas (what overlay2 wants for
  # per-container storage limits). Docker's default data-root
  # (/var/lib/docker) therefore lives on XFS, not btrfs.
  disko.devices.lvm_vg.data = {
    type = "lvm_vg";
    lvs = {
      docker = {
        size = "512G";
        content = {
          type = "filesystem";
          format = "xfs";
          mountpoint = "/var/lib/docker";
          mountOptions = [
            "noatime"
            "pquota"
          ];
        };
      };
      home = {
        size = "100%FREE";
        content = {
          type = "filesystem";
          format = "xfs";
          mountpoint = "/home";
          mountOptions = [
            "noatime"
            "nodiratime"
            "inode64"
            "largeio"
          ];
        };
      };
    };
  };
}
