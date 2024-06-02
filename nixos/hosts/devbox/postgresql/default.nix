{ lib, ... }:
{
  fileSystems."/var/lib/postgresql" = {
    device = "/dev/data/postgresql";
    fsType = "ext4";
  };
  services.postgresql = {
    enable = true;
    dataDir = "/var/lib/postgresql/data";
    authentication = ''
      # Generated file; do not edit!
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';
  };
}
