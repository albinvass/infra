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

