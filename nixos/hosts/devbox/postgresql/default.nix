{ lib, ... }: {
  services.postgresql = {
    enable = lib.mkDefault true;
    dataDir = "/opt/data/postgresql";
    authentication = ''
      # Generated file; do not edit!
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     trust
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';
  };
}

