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

  services.frp.settings.proxies = [
    {
      name = "HTTP authentik.albinvass.se";
      customDomains = ["authentik.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS authentik.albinvass.se";
      customDomains = ["authentik.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];
  services.nginx.virtualHosts = {
    "authentik.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:14080";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $proxy_protocol_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
        '';
      };
      extraConfig = ''
          client_max_body_size 20000M;
      '';
    };
  };
}

