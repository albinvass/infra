{ config, pkgs, ...}:
{
  users.users."authentik" = {
    name = "authentik";
    group = "authentik";
    isSystemUser = true;
  };

  users.groups."authentik" = {};

  sops.secrets = {
    "authentik/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "authentik/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "authentik/restic/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  services.restic.backups.authentik = {
    initialize = true;
    package =
      let
        runitorWrappedRestic = pkgs.writeShellScriptBin "restic"
          ''
            #!${pkgs.bash}/bin/bash
            ${pkgs.runitor}/bin/runitor -- ${pkgs.restic}/bin/restic "$@"
          '';
      in runitorWrappedRestic;
    backupPrepareCommand = ''
      #!${pkgs.bash}/bin/bash

      ${pkgs.docker-client}/bin/docker compose exec database bash -c 'pg_dumpall --user=$POSTGRES_USER ----file=/opt/database-backups/$(date "+%F-%T").bkp'
    '';
    passwordFile = config.sops.secrets."authentik/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."authentik/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."authentik/restic/environmentFile".path;
    paths = [
      "/opt/authentik"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
  };

  services.webProxy.services = {
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

