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

