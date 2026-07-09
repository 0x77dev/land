# Full-disk-encryption target for the reinstall. NOT imported yet — swap
# the `./disko-config.nix` import for `./fde.nix` when executing.
#
# Both NVMes are TCG OPAL 2.0 self-encrypting drives (verified with
# `nvme sed discover`: locking supported, currently unowned). Encryption
# strategy per volume:
#
#   Samsung PM9A3 (system, btrfs): LUKS2 *stacked on* the OPAL hardware
#     locking range (`cryptsetup --hw-opal`). dm-crypt stays load-bearing —
#     OPAL firmware alone has historically failed to bind passphrases to
#     the media key (CVE-2018-12037/-12038) — while OPAL adds defence in
#     depth and instant admin-PIN crypto-erase. Never `--hw-opal-only`.
#
#   Crucial T500 (/scratch, XFS): OPAL locking range *only*, managed with
#     sedutil at boot — no dm layer at all, because GPUDirect Storage's
#     direct NVMe->GPU DMA path does not survive device-mapper. This gives
#     hardware encryption at rest without costing the GDS fast path.
#
# Runbook:
#   0. Copy anything precious off both disks (everything is reformatted).
#   1. Generate and escrow (1Password) two secrets:
#        - OPAL admin PIN  -> /run/opal-admin.key   (one printable line)
#        - scratch SID PIN -> used with sedutil below
#   2. Swap the import in default.nix: ./disko-config.nix -> ./fde.nix,
#      and place the admin PIN file on the installer at /run/opal-admin.key
#      (nixos-anywhere: `--copy-file`).
#   3. `nixos-anywhere --flake .#muscle root@muscle` — disko runs
#      luksFormat --hw-opal, taking OPAL ownership of the PM9A3 with the
#      admin PIN and prompting for the LUKS passphrase.
#   4. First boot: TPM-enroll the system volume (PCR 7 is stable):
#        systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 \
#          /dev/disk/by-id/nvme-SAMSUNG_MZQL27T6HBLA-00A07_S6CKNN0X600716-part2
#   5. Take scratch ownership and seal its PIN to the TPM:
#        sedutil-cli --initialSetup <pin> /dev/nvme0n1
#        sedutil-cli --enableLockingRange 0 <pin> /dev/nvme0n1
#        printf '%s' '<pin>' | systemd-creds encrypt --with-key=tpm2 \
#          --name=scratch-opal - /etc/credstore.encrypted/scratch-opal
#      (Until step 5 the scratch service no-ops and /scratch mounts plain.)
{
  lib,
  pkgs,
  ...
}:
{
  # systemd in the initrd: required for TPM2 LUKS unlock.
  boot.initrd.systemd.enable = true;

  # Swap moves to a btrfs-native swapfile subvolume (below).
  swapDevices = lib.mkForce [ ];

  # Btrfs upkeep: monthly scrub for checksummed self-healing, weekly TRIM.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  services.fstrim.enable = true;

  environment.systemPackages = [ pkgs.sedutil ];

  # /var/lib/docker sits on a nodatacow btrfs subvolume; run overlay2 on it
  # explicitly (the auto-detected `btrfs` driver is deprecated and its
  # per-layer subvolumes fight scrubs and quotas).
  virtualisation.docker.daemon.settings.storage-driver = "overlay2";

  # Unlock the T500's OPAL locking range before /scratch mounts. The PIN is
  # a TPM2-sealed systemd credential (step 5 of the runbook); before it is
  # enrolled, or on an unowned drive, this exits cleanly and the mount
  # proceeds (range unlocked/not yet enabled).
  systemd.services.scratch-opal-unlock = {
    description = "Unlock OPAL locking range for /scratch";
    wantedBy = [ "local-fs.target" ];
    before = [ "scratch.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      LoadCredentialEncrypted = "scratch-opal:/etc/credstore.encrypted/scratch-opal";
    };
    script = ''
      pin_file="$CREDENTIALS_DIRECTORY/scratch-opal"
      [ -s "$pin_file" ] || exit 0
      ${lib.getExe' pkgs.sedutil "sedutil-cli"} \
        --setLockingRange 0 RW "$(cat "$pin_file")" /dev/nvme0n1 || true
      ${lib.getExe' pkgs.sedutil "sedutil-cli"} \
        --setMBRDone on "$(cat "$pin_file")" /dev/nvme0n1 || true
    '';
  };
  fileSystems."/scratch".options = [ "x-systemd.requires=scratch-opal-unlock.service" ];

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
              # Create-time recovery key (nixos-anywhere --disk-encryption-keys
              # places it); fed to luksFormat via process substitution so stdin
              # stays free for the OPAL admin PIN below.
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
  };
}
