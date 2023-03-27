{ config, lib, pkgs, modulesPath, ... }:
{
  networking.firewall.allowedTCPPorts = [ 80 443 8448 ];
  security.acme.defaults.email = "albin.vass@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs = {
    "vassast.org" = {
      webroot = "/var/lib/acme/.challenges";
      email = "albin.vass@gmail.com";
      group = "nginx";
      extraDomainNames = [
        "matrix.vassast.org"
        "minio.vassast.org"
        "s3.vassast.org"
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
          port = 80;
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
          port = 443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://synapse:8008";
        };
      };
      "s3.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://minio:9000/";
          proxyWebsockets = true;
        };
      };
      "minio.vassast.org" = {
        forceSSL = true;
        useACMEHost = "vassast.org";
        listen = [{
          addr = "0.0.0.0";
          port = 443;
          ssl = true;
        }];
        locations."/" = {
          proxyPass = "http://minio:9001/";
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
            proxyPass = "http://synapse:8008";
          };
          "/_synapse/client/" = {
            proxyPass = "http://synapse:8008";
          };
        };
      };
    };
  };
}

