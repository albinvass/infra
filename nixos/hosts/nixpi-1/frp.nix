{ config, ... }:

{
  sops.secrets = {
    "frp/tls/certFile" = { };
    "frp/tls/keyFile" = { };
    "frp/tls/trustedCaFile" = { };
  };

  imports = [
    ../../modules/frp-client-base
  ];

  # TODO: generate virtualHosts and frp proxies
  services.nginx.virtualHosts = {
    "albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:8787";
      };
    };
    "calibre.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://192.168.50.131:8083";
      };
      extraConfig = ''
          client_max_body_size 5000M;
      '';
    };
    "homeassistant.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      listen = [
        {
          addr = "0.0.0.0";
          ssl = false;
          port = 80;
        }
        {
          addr = "0.0.0.0";
          ssl = true;
          port = 443;
          proxyProtocol = true;
        }
      ];
      locations."/" = {
        proxyPass = "http://homeassistant:8123";
        proxyWebsockets = true;
        recommendedProxySettings = false;
        extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $proxy_protocol_addr;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
          proxy_set_header        X-Forwarded-For $proxy_protocol_addr;
        '';
      };
      extraConfig = ''
          client_max_body_size 5000M;
      '';
    };
    "immich.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://192.168.50.131:2283";
      };
      extraConfig = ''
          client_max_body_size 20000M;
      '';
    };
    "jellyfin.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://192.168.50.131:8096";
      };
    };
    "jellyseerr.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://192.168.50.131:5055";
      };
    };
    "matrix.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:8008";
      };
      extraConfig = ''
          client_max_body_size 5000M;
      '';
    };
    "navidrome.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://192.168.50.131:4533";
      };
    };
    "storage.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://storage.:5000";
        proxyWebsockets = true;
      };
      extraConfig = ''
          client_max_body_size 20000M;
      '';
    };
  };
  services.frp = {
    settings = {
      proxies = [
        {
          name = "HTTP albinvass.se";
          customDomains = ["albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS albinvass.se";
          customDomains = ["albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP calibre.albinvass.se";
          customDomains = ["calibre.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS calibre.albinvass.se";
          customDomains = ["calibre.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP homeassistant.albinvass.se";
          customDomains = ["homeassistant.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
          transport.proxyProtocolVersion = "v2";
        }
        {
          name = "HTTPS homeassistant.albinvass.se";
          customDomains = ["homeassistant.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
          transport.proxyProtocolVersion = "v2";
        }
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
        }
        {
          name = "HTTP jellyfin.albinvass.se";
          customDomains = ["jellyfin.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS jellyfin.albinvass.se";
          customDomains = ["jellyfin.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP jellyseerr.albinvass.se";
          customDomains = ["jellyseerr.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS jellyseerr.albinvass.se";
          customDomains = ["jellyseerr.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP matrix.albinvass.se";
          customDomains = ["matrix.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS matrix.albinvass.se";
          customDomains = ["matrix.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP navidrome.albinvass.se";
          customDomains = ["navidrome.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS navidrome.albinvass.se";
          customDomains = ["navidrome.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
        {
          name = "HTTP storage.albinvass.se";
          customDomains = ["storage.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
        }
        {
          name = "HTTPS storage.albinvass.se";
          customDomains = ["storage.albinvass.se"];
          type = "https";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultSSLListenPort;
        }
      ];
    };
  };
}
