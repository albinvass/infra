{ config, pkgs, ...}:
{
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    docker
  ];
  users.users."immich" = {
    name = "immich";
    group = "immich";
    isSystemUser = true;
  };

  users.groups."immich" = {};

  sops.secrets = {
    "cifs" = { };

    "immich/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "immich/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "immich/restic/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  services.restic.backups.immich = {
    initialize = true;
    passwordFile = config.sops.secrets."immich/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."immich/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."immich/restic/environmentFile".path;
    paths = [
      "/var/lib/immich"
      "/opt/immich"
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

  fileSystems."/var/lib/immich" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "immich";
      group = "immich";
    in [ "${automount_opts},credentials=${config.sops.secrets."cifs".path},uid=${user},gid=${group}" ];
  };

  services.frp.settings.proxies = [
    {
      name = "HTTP immich.albinvass.se";
      customDomains = ["immich.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS immich.albinvass.se";
      customDomains = ["immich.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];
  services.nginx.virtualHosts = {
    "immich.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:2283";
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
