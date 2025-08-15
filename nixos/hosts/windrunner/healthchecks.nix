{ config, ... }:
{
  sops.secrets = {
    "healthchecks/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "healthchecks/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "healthchecks/restic/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "healthchecks/SECRET_KEY_FILE" = {
      owner = config.services.healthchecks.user;
      group = config.services.healthchecks.group;
      mode = "0600";
    };
  };

  services.healthchecks = {
    enable = true;
    settings = {
      SECRET_KEY_FILE = config.sops.secrets."healthchecks/SECRET_KEY_FILE".path;
      SITE_ROOT = "https://healthchecks.albinvass.se";
    };
  };

  services.frp.settings.proxies = [
    {
      name = "HTTP healthchecks.albinvass.se";
      customDomains = [ "healthchecks.albinvass.se" ];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS healthchecks.albinvass.se";
      customDomains = [ "healthchecks.albinvass.se" ];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];

  services.nginx.virtualHosts = {
    "healthchecks.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
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
    };
  };
}
