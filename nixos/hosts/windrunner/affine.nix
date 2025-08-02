{ config, pkgs, ...}:
{
  users.users."affine" = {
    name = "affine";
    group = "affine";
    isSystemUser = true;
  };

  users.groups."affine" = {};

  sops.secrets = {
    "affine/cifs" = { };

    "affine/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "affine/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "affine/restic/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  services.restic.backups.affine = {
    initialize = true;
    package =
      let
        runitorWrappedRestic = pkgs.writeShellScriptBin "restic"
          ''
            #!${pkgs.bash}/bin/bash
            ${pkgs.runitor}/bin/runitor -- ${pkgs.restic}/bin/restic "$@"
          '';
      in runitorWrappedRestic;
    passwordFile = config.sops.secrets."affine/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."affine/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."affine/restic/environmentFile".path;
    paths = [
      "/var/lib/affine"
      "/opt/affine"
    ];
    exclude = [
      "\#recycle"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
  };

  fileSystems."/var/lib/affine" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "affine";
      group = "affine";
    in [ "${automount_opts},credentials=${config.sops.secrets."affine/cifs".path},uid=${user},gid=${group},nobrl" ];
  };

  services.frp.settings.proxies = [
    {
      name = "HTTP affine.albinvass.se";
      customDomains = ["affine.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS affine.albinvass.se";
      customDomains = ["affine.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];
  services.nginx.virtualHosts = {
    "affine.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3010";
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
