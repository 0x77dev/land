# Target layout for the full-disk-encryption migration. NOT imported yet:
# the root filesystem is XFS (cannot shrink), so switching requires a
# reinstall via nixos-anywhere rather than in-place re-encryption.
#
# Migration runbook:
#   1. Back up /home (and anything else stateful) off-machine.
#   2. Swap the disko-config.nix import for this file and set
#      `boot.initrd.systemd.enable = true;` on muscle.
#   3. `nixos-anywhere --flake .#muscle root@muscle` — disko formats with
#      LUKS2 and prompts for the passphrase.
#   4. After first boot, bind the key to the TPM (PCR 7 is stable now that
#      Secure Boot + measured UKIs are in place):
#        systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
#          /dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716-part2
#   5. Restore /home. Swapfile lives on the encrypted root, which also
#      resolves the fwupd "Linux Swap: Not Encrypted" finding.
{
  disko.devices = {
    disk = {
      main = {
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
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                  bypassWorkqueues = true;
                };
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = "/";
                  mountOptions = [
                    "noatime"
                    "nodiratime"
                    "inode64"
                    "largeio"
                    "swalloc"
                  ];
                  extraArgs = [
                    "-d"
                    "agcount=32"
                    "-l"
                    "size=256m"
                    "-n"
                    "size=8192"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
