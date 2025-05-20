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
    "calibre.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://192.168.50.131:8083";
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
          client_max_body_size 5000M;
      '';
    };
    "homeassistant.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://homeassistant:8123";
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
          client_max_body_size 5000M;
      '';
    };
    "jellyfin.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://windrunner:8096";
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
    "jellyseerr.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://windrunner:5055";
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
    "matrix.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:8008";
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
          client_max_body_size 5000M;
      '';
    };
    "storage.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://storage.:5000";
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
          transport.proxyProtocolVersion = "v2";
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
          transport.proxyProtocolVersion = "v2";
        }
        {
          name = "HTTP homeassistant.albinvass.se";
          customDomains = ["homeassistant.albinvass.se"];
          type = "http";
          localIP = config.networking.hostName;
          localPort = config.services.nginx.defaultHTTPListenPort;
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
          transport.proxyProtocolVersion = "v2";
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
          transport.proxyProtocolVersion = "v2";
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
          transport.proxyProtocolVersion = "v2";

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
          transport.proxyProtocolVersion = "v2";
        }
        {
          name = "SSH nixpi-1";
          type = "tcp";
          localIP = config.networking.hostName;
          localPort = 22;
          remotePort = 1022;
        }
      ];
    };
  };
}
