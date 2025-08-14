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

  # Configure all proxy services in one place
  services.webProxy.services = {
    "albinvass.se" = {
      backend = {
        host = "localhost";
        port = 8787;
      };
      ssl = true;
      websockets = false;
      clientMaxBodySize = "5000M";
    };

    "calibre.albinvass.se" = {
      backend = {
        host = "192.168.50.131";
        port = 8083;
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

  # Additional SSH proxy configurations
  services.frp.settings.proxies = [
    {
      name = "SSH nixpi-1";
      type = "tcp";
      localIP = config.networking.hostName;
      localPort = 22;
      remotePort = 1022;
    }
  ];
}
