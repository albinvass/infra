{ config, lib, pkgs, modulesPath, ... }:
{
  security.acme.defaults.email = "albin.vass@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs = {
    "vassast.org" = {
      webroot = "/var/lib/acme/.challenges";
      email = "albin.vass@gmail.com";
      group = "nginx";
      extraDomainNames = [
        "matrix.vassast.org"
        "plex.vassast.org"
      ];
    };
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    virtualHosts = {
      "acmechallenge.vassast.org" = {
        serverAliases = [ "*.vassast.org" ];
        listen = [{
          addr = "0.0.0.0";
          port = 8080;
          ssl = false;
        }];
        locations."/.well-known/acme-challenge" = {
          root = "/var/lib/acme/.challenges";
        };
        locations."/" = {
          return = "301 https://$host$request_uri";
        };
      };
      "plex.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://nixos:32400/";
        };
      };
      "matrix.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://nixos:80";
        };
      };
      "vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8448;
          ssl = true;
        }];
        locations = {
          "/_matrix/" = {
            proxyPass = "http://nixos:80";
          };
          "/_synapse/client/" = {
            proxyPass = "http://nixos:80";
          };
        };
      };
      "nixos" = {
        listen = [{
          addr = "0.0.0.0";
          port = 8080;
          ssl = false;
        }];
        locations = {
          "${config.services.kibana.extraConf.server.basePath}" = {
            proxyPass = "http://localhost:5601";
          };
          "/" = {
            proxyPass = "http://nixos:80";
          };
        };
      };
    };
  };
}
