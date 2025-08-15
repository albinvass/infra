{ config, pkgs, ...}:
{
  users.users."authentik" = {
    name = "authentik";
    group = "authentik";
    isSystemUser = true;
  };

  users.groups."authentik" = {};

  albinvass.resticBackup.services.authentik = {
    paths = [
      "/opt/authentik"
    ];
    backupPrepareCommand = ''
      #!${pkgs.bash}/bin/bash

      ${pkgs.docker-client}/bin/docker compose exec database bash -c 'pg_dumpall --user=$POSTGRES_USER ----file=/opt/database-backups/$(date "+%F-%T").bkp'
    '';
  };

  albinvass.webProxy.services = {
    "authentik.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = 14080;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };
}

