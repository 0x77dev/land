# Full-disk-encryption target for the reinstall. NOT imported yet — swap
# the `./disko-config.nix` import for `./fde.nix` when executing.
#
# Layout:
#   Crucial T500 2TB    -> /scratch: the whole disk as unencrypted XFS for
#                          GPUDirect Storage. Both NVMes negotiate Gen4 x4,
#                          so the T500 wins as scratch by having the higher
#                          burst read rate and, decisively, a dedicated
#                          controller with zero competing system IO.
#                          (True GDS DMA requires XFS/ext4 + O_DIRECT and
#                          no dm-crypt underneath.)
#   Samsung PM9A3 7.6TB -> everything else: LUKS2 + btrfs (fully btrfs
#                          system: root, nix, home, docker, log, swap as
#                          subvolumes), zstd:1 compression, async discard.
#                          The PM9A3's datacenter QoS and endurance suit
#                          the always-on system + home role.
#
# Runbook:
#   0. Copy anything precious off the current root (the PM9A3 is
#      reformatted; the T500's old Windows install dies too).
#   1. Swap the import in default.nix: ./disko-config.nix -> ./fde.nix.
#   2. `nixos-anywhere --flake .#muscle root@muscle` (disko formats and
#      prompts for the LUKS passphrase).
#   3. First boot: enroll the system volume into the TPM (PCR 7 is stable
#      with Secure Boot + measured UKIs):
#        systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
#          /dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716-part2
#   4. Restore /home data.
{ lib, ... }:
{
  # systemd in the initrd: required for TPM2 LUKS unlock.
  boot.initrd.systemd.enable = true;

  # Swap moves to a btrfs-native swapfile subvolume (below).
  swapDevices = lib.mkForce [ ];

  # Btrfs upkeep: monthly scrub for checksummed self-healing, weekly TRIM
  # (allowDiscards is set on the LUKS volume; async discard on the mounts).
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  services.fstrim.enable = true;

  disko.devices.disk = {
    scratch = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-CT2000T500SSD8_241047BE2CB4";
      content = {
        type = "gpt";
        partitions.scratch = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/scratch";
            mountOptions = [
              "noatime"
              "nodiratime"
              "largeio"
            ];
          };
        };
      };
    };

    system = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716";
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
              content =
                let
                  fast = [
                    "compress=zstd:1"
                    "noatime"
                    "discard=async"
                  ];
                in
                {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = fast;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = fast;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = fast;
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = fast;
                    };
                    # Container write paths hate CoW: no copy-on-write (and
                    # therefore no compression/checksums) for docker's
                    # overlay2 store.
                    "@docker" = {
                      mountpoint = "/var/lib/docker";
                      mountOptions = [
                        "nodatacow"
                        "noatime"
                        "discard=async"
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
  };
}
