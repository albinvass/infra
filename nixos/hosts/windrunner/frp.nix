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

  albinvass.webProxy.services = {
    "jellyfin.albinvass.se" = {
      backend = {
        host = "localhost";
        port = 8096;
      };
      ssl = true;
      websockets = false;
      clientMaxBodySize = "5000M";
    };

    "jellyseerr.albinvass.se" = {
      backend = {
        host = "localhost";
        port = 5055;
      };
      ssl = true;
      websockets = false;
      clientMaxBodySize = null;
    };

    "albinvass.se" = {
      backend = {
        host = "nixpi-1";
        port = 8787;
      };
      ssl = true;
      websockets = false;
      clientMaxBodySize = "5000M";
    };

    "homeassistant.albinvass.se" = {
      backend = {
        host = "homeassistant";
        port = 8123;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "5000M";
    };

    "storage.albinvass.se" = {
      backend = {
        host = "storage";
        port = 5000;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };

  services.frp = {
    settings = {
      proxies = [
        {
          name = "SSH windrunner";
          type = "tcp";
          localIP = config.networking.hostName;
          localPort = 22;
          remotePort = 3022;
        }
      ];
    };
  };
}
