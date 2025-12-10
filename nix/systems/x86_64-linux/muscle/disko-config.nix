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
              size = "512M";
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
}
