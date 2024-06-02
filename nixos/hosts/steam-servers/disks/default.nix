{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];
  disko.devices = {
    disk = {
      os = {
        # OS disk
        device = "/dev/disk/by-path/pci-0000:06:00.0-scsi-0:0:0:0";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1M";
              type = "EF02";
            };
            esp = {
              name = "ESP";
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
      data = {
        device = "/dev/disk/by-path/pci-0000:06:00.0-scsi-0:0:0:1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            data = {
              name = "data";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "data";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
      data = {
        type = "lvm_vg";
        lvs = {
          data = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var/lib";
              mountOptions = [ "defaults" ];
            };
          };
        };
      };
    };
  };
}
