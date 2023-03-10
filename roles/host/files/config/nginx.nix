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
        "assistant.vassast.org"
        "s3.vassast.org"
        "minio.vassast.org"
      ];
    };
  };
  services.nginx = {
    clientMaxBodySize = "1000m";
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
      "matrix.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://localhost:80";
        };
      };
      "assistant.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://localhost:80/";
          proxyWebsockets = true;
        };
      };
      "s3.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://localhost:80/";
          proxyWebsockets = true;
        };
      };
      "minio.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 8443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://localhost:80/";
          proxyWebsockets = true;
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
            proxyPass = "http://localhost:80";
          };
          "/_synapse/client/" = {
            proxyPass = "http://localhost:80";
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
          "/" = {
            proxyPass = "http://localhost:80";
          };
        };
      };
      "nixos.local.vassast.org" = {
        listen = [{
          addr = "0.0.0.0";
          port = 8080;
          ssl = false;
        }];
        locations = {
          "/" = {
            proxyPass = "http://localhost:80";
          };
        };
      };
    };
  };
}
