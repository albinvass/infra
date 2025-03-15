{ config, ... }:
let
  frpPort = 7000;
  frpHTTPPort = 80;
  frpHTTPSPort = 443;
in
{
  sops.secrets = {
    "frp/tls/certFile" = { };
    "frp/tls/keyFile" = { };
    "frp/tls/trustedCaFile" = { };
  };

  networking.firewall.allowedTCPPorts = [
    frpPort
    frpHTTPPort
    frpHTTPSPort
    1022
    2022
    3022
  ];
  systemd.services.frp.serviceConfig = {
    LoadCredential = [
      "certFile:${config.sops.secrets."frp/tls/certFile".path}"
      "keyFile:${config.sops.secrets."frp/tls/keyFile".path}"
      "trustedCaFile:${config.sops.secrets."frp/tls/trustedCaFile".path}"
    ];
  };
  services.frp = {
    enable = true;
    role = "server";
    settings = {
      bindPort = frpPort;
      proxyBindAddr = "0.0.0.0";
      vhostHTTPPort = frpHTTPPort;
      vhostHTTPSPort = frpHTTPSPort;
      transport = {
        tls = {
          force = true;
          certFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/certFile";
          keyFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/keyFile";
          trustedCaFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/trustedCaFile";
        };
      };
    };
  };
}
