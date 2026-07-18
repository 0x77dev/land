# Active full-disk-encryption layout, installed 2026-07-09.
#
# The Samsung PM9A3 system disk is a TCG OPAL 2.0 self-encrypting drive
# (verified with `nvme sed discover`: locking supported). LUKS2 is stacked
# on the OPAL hardware locking range (`cryptsetup --hw-opal`). dm-crypt
# stays load-bearing — OPAL firmware alone has historically failed to bind
# passphrases to the media key (CVE-2018-12037/-12038) — while OPAL adds
# defence in depth and instant admin-PIN crypto-erase. Never use
# `--hw-opal-only`.
#
# The Crucial T500 is intentionally absent from this configuration so a
# separate Windows installation owns the whole drive.
#
# Recovery/reinstall runbook:
#   0. Back up the system disk; disko reformats it.
#   1. Generate and escrow (1Password) distinct LUKS recovery and OPAL
#      admin secrets, each as one printable line.
#   2. Install with both secrets available before disko runs:
#        nixos-anywhere \
#          --disk-encryption-keys /tmp/cryptsystem.key <local-luks-key-file> \
#          --disk-encryption-keys /run/opal-admin.key <local-opal-pin-file> \
#          --flake .#muscle root@muscle
#      This runs `luksFormat --hw-opal` and takes OPAL ownership of the
#      PM9A3 without exposing either secret through the Nix store.
#   3. Boot the installed generation once so Lanzaboote creates its managed
#      PCR policy, then replace any static TPM enrollment with that policy:
#        systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto \
#          --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
#          /dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716-part2
#      Keep the recovery passphrase: it is required if the TPM or measured
#      boot policy is unavailable.
_: {
  # systemd in the initrd: required for TPM2 LUKS unlock.
  boot.initrd.systemd.enable = true;

  # Authorize the signed Linux boot generations through systemd-pcrlock's
  # managed PCR 4 policy. Do not bind to PCR 7: Windows/firmware Secure Boot
  # db/dbx updates legitimately change it and strand a static LUKS enrollment.
  # Lanzaboote updates this policy as generations are installed, so kernel and
  # initrd updates do not require re-enrollment.
  boot.lanzaboote = {
    configurationLimit = 8;
    measuredBoot = {
      enable = true;
      pcrs = [ 4 ];
    };
  };

  # Btrfs upkeep: monthly scrub for checksummed self-healing, weekly TRIM.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  services.fstrim.enable = true;

  disko.devices.disk.system = {
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
            # Create-time recovery key (nixos-anywhere
            # --disk-encryption-keys places it); fed to luksFormat via
            # process substitution so stdin stays free for the OPAL admin
            # PIN below.
            passwordFile = "/tmp/cryptsystem.key";
            settings = {
              allowDiscards = true;
              bypassWorkqueues = true;
              crypttabExtraOpts = [ "tpm2-device=auto" ];
            };
            # Stack dm-crypt on the OPAL hardware locking range. cryptsetup
            # has no CLI flag for the OPAL admin PIN — luksFormat reads it
            # from stdin when stdin is not a TTY, and disko splices these
            # args verbatim into the shell command, so a redirection can
            # ride along. The LUKS passphrase arrives via --key-file,
            # leaving stdin free for the PIN.
            extraFormatArgs = [
              "--hw-opal"
              "</run/opal-admin.key"
            ];
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
}
