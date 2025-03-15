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
          name = "SSH nixpi-3";
          type = "tcp";
          localIP = config.networking.hostName;
          localPort = 22;
          remotePort = 3022;
        }
      ];
    };
  };
}

