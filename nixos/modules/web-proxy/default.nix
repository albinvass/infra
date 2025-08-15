{ config, lib, ... }:

with lib;

let
  cfg = config.albinvass.webProxy;

  # Standard proxy headers for all services
  standardProxyHeaders = ''
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $proxy_protocol_addr;
    proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $host;
    proxy_set_header        X-Forwarded-Port $server_port;
  '';

  # Generate nginx virtual host configuration
  generateVirtualHost = domain: service: {
    forceSSL = service.ssl;
    enableACME = service.ssl;
    locations."/" = {
      proxyPass = "http://${service.backend.host}:${toString service.backend.port}";
      proxyWebsockets = service.websockets;
      extraConfig =
        standardProxyHeaders + (optionalString (service.extraNginxConfig != "") service.extraNginxConfig);
    };
    extraConfig = optionalString (service.clientMaxBodySize != null) ''
      client_max_body_size ${service.clientMaxBodySize};
    '';
  };

  # Generate frp proxy configurations
  generateFrpProxies =
    domain: service:
    [
      {
        name = "HTTP ${domain}";
        customDomains = [ domain ];
        type = "http";
        localIP = config.networking.hostName;
        localPort = config.services.nginx.defaultHTTPListenPort;
      }
    ]
    ++ (optionals service.ssl [
      {
        name = "HTTPS ${domain}";
        customDomains = [ domain ];
        type = "https";
        localIP = config.networking.hostName;
        localPort = config.services.nginx.defaultSSLListenPort;
        transport.proxyProtocolVersion = "v2";
      }
    ]);

in
{
  options.albinvass.webProxy = {
    services = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            backend = {
              host = mkOption {
                type = types.str;
                default = "127.0.0.1";
                description = "Backend service host";
              };
              port = mkOption {
                type = types.port;
                description = "Backend service port";
              };
            };
            ssl = mkOption {
              type = types.bool;
              default = true;
              description = "Enable SSL/TLS with ACME";
            };
            websockets = mkOption {
              type = types.bool;
              default = false;
              description = "Enable WebSocket support";
            };
            clientMaxBodySize = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Maximum client body size (e.g., '5000M')";
            };
            extraNginxConfig = mkOption {
              type = types.str;
              default = "";
              description = "Additional nginx configuration";
            };
          };
        }
      );
      default = { };
      description = "Web services to proxy (supports both single and multiple services)";
    };
  };

  config = mkIf (cfg.services != { }) {
    services.nginx.virtualHosts = mapAttrs generateVirtualHost cfg.services;

    services.frp.settings.proxies = flatten (mapAttrsToList generateFrpProxies cfg.services);
  };
}
