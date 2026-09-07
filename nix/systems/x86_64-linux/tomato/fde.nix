# Full-disk-encryption layout for tomato's mirrored ZFS root.
#
# Both Samsung 990 PRO 4TB partitions are LUKS2 volumes; the ZFS mirror
# (`zroot`) sits on the two dm-crypt mappers. TPM self-seal uses
# systemd-pcrlock's managed PCR 4 policy (same as muscle), so kernel/initrd
# updates do not require re-enrollment. Do not bind to PCR 7: firmware Secure
# Boot db/dbx updates legitimately change it and strand a static enrollment.
#
# ZFS native encryption is deliberately NOT used: systemd-cryptenroll cannot
# seal it, so there would be no TPM self-seal.
#
# The Kingston 1TB is the boot device — ESP + sbctl keys + lanzaboote-signed
# UKIs — and holds no data. It stays unencrypted (Secure Boot's signed UKI
# covers tampering); its remaining space is unallocated.
#
# Recovery/reinstall runbook:
#   0. Back up /data; disko reformats all three disks.
#   1. Generate and escrow (1Password) one LUKS recovery passphrase as a
#      printable line.
#   2. Install with the passphrase available before disko runs:
#        nixos-anywhere \
#          --disk-encryption-keys /tmp/cryptsystem.key <local-luks-key-file> \
#          --flake .#tomato root@<host>
#      disko runs `luksFormat` on both Samsung partitions with that passphrase.
#   3. Boot the installed generation once so Lanzaboote creates its managed
#      PCR policy, then enroll each LUKS device against it:
#        for part in \
#          /dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117852T-part1 \
#          /dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117856R-part1; do
#          systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto \
#            --tpm2-pcrlock=/var/lib/systemd/pcrlock.json "$part"
#        done
#      Keep the recovery passphrase: required if the TPM or measured-boot
#      policy is unavailable.
#   4. If the TPM/pcrlock path fails at boot, the box drops to initrd-SSH on
#      port 2222: SSH in (root, YubiKey key) and unlock both LUKS devices:
#        systemd-cryptsetup attach cryptroot1 /dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117852T-part1
#        systemd-cryptsetup attach cryptroot2 /dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0Y117856R-part1
#      Boot then continues into the full system.
_: {
  boot = {
    # systemd in the initrd: required for TPM2 LUKS unlock and for initrd-SSH
    # networking.
    initrd.systemd.enable = true;

    # Authorize the signed Linux boot generations through systemd-pcrlock's
    # managed PCR 4 policy. Lanzaboote updates this policy as generations are
    # installed, so kernel and initrd updates do not require re-enrollment.
    lanzaboote = {
      configurationLimit = 8;
      measuredBoot = {
        enable = true;
        pcrs = [ 4 ];
      };
    };

    # Out-of-band LUKS recovery for a headless box: sshd in the initramfs on the
    # LAN, so cryptroot1/2 can be unlocked remotely if the TPM/pcrlock policy
    # fails to unseal (or if the TPM is absent). Reuses mykhailo's YubiKey keys
    # (same source as the user-keys module). The initrd host key is provisioned
    # out-of-band at install (kept OUT of the Nix store — store keys are
    # world-readable); do NOT reuse the running sshd's host keys here.
    initrd.network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222; # distinct from the running sshd (22)
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhgGGgMgUf9UysNVEb41g+niAkaqYTMx3CXgxcFMPSb cardno:24_377_114"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLwgUmfKE8SDO7FJ4tUT4rPS/OraXAmrqQYj47zeF8LUWpJc12few20m4IcFkpC9/+C+O1LdSwNCL4I243JwKMQ= cardno:24_377_114"
        ];
        # Provisioned at install: ssh-keygen -t ed25519 -N "" -f /var/lib/initrd-ssh/ssh_host_ed25519_key
        hostKeys = [ "/var/lib/initrd-ssh/ssh_host_ed25519_key" ];
      };
    };
  };

  # Weekly TRIM on the encrypted volumes (no async discard under dm-crypt).
  services.fstrim.enable = true;
}
