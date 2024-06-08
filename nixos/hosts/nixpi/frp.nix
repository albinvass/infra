{ config, ... }:

{
  sops.secrets = {
    "frp/tls/certFile" = { };
    "frp/tls/keyFile" = { };
    "frp/tls/trustedCaFile" = { };
  };

  systemd.services.frp.serviceConfig = {
    LoadCredential = [
      "certFile:${config.sops.secrets."frp/tls/certFile".path}"
      "keyFile:${config.sops.secrets."frp/tls/keyFile".path}"
      "trustedCaFile:${config.sops.secrets."frp/tls/trustedCaFile".path}"
    ];
  };
  services.frp = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = "reverse-proxy.albinvass.se";
      serverPort = 7000;
      transport = {
        tls = {
          certFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/certFile";
          keyFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/keyFile";
          trustedCaFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/trustedCaFile";
        };
      };
      proxies = [
        {
          name = "attic.albinvass.se";
          type = "tcp";
          remotePort = 8082;
          localIP = "127.0.0.1";
          localPort = 8080;
        }
        {
          name = "storage.albinvass.se";
          type = "tcp";
          remotePort = 8083;
          localIP = "storage.";
          localPort = 8080;
        }
      ];
    };
  };
}
