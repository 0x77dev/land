{
  disko.devices = {
    disk = {
      emmc = {
        type = "disk";
        # eMMC device path - typically /dev/mmcblk0 for RPi5/CM5
        # Verify actual device path with: lsblk
        device = "/dev/mmcblk0";
        content = {
          type = "gpt";
          partitions = {
            # RPi firmware partition (FAT32)
            firmware = {
              size = "512M";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/firmware";
                mountOptions = [ "umask=0077" ];
              };
            };
            # Root partition (ext4 for simplicity and reliability on RPi)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "noatime"
                  "nodiratime"
                ];
              };
            };
          };
        };
      };
    };
  };
}
