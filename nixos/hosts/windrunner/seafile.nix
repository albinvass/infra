{ config, pkgs, ...}:
{
  users.users."seafile" = {
    name = "seafile";
    group = "seafile";
    uid = 989;
    isSystemUser = true;
  };

  users.groups."seafile" = {
    gid = 987;
  };

  sops.secrets = {
    "seafile/cifs" = { };
  };

  albinvass.resticBackup.services.seafile = {
    paths = [
      "/var/lib/seafile"
      "/opt/seafile"
    ];
    exclude = [
      "\#recycle"
    ];
  };

  fileSystems."/var/lib/seafile" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "seafile";
      group = "seafile";
    in [ "${automount_opts},credentials=${config.sops.secrets."seafile/cifs".path},uid=${user},gid=${group}" ];
  };

  services.frp.settings.proxies = [
    {
      name = "HTTP seafile.albinvass.se";
      customDomains = ["seafile.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS seafile.albinvass.se";
      customDomains = ["seafile.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];
  services.nginx.virtualHosts = {
    "seafile.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3283";
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

