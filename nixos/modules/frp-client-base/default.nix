{ config, ... }:
let
  defaultHTTPListenPort = 80;
  defaultSSLListenPort = 443;
in
{
  networking.firewall.allowedTCPPorts = [
    defaultHTTPListenPort
    defaultSSLListenPort
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "letsencrypt.org@mail.albinvass.com";
  };
  services.nginx = {
    inherit defaultHTTPListenPort defaultSSLListenPort;
    enable = true;
    recommendedProxySettings = true;
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
    };
  };
}


