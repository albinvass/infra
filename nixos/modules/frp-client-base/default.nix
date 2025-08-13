{ config, ... }:
let
  defaultHTTPListenPort = 80;
  defaultSSLListenPort = 443;
in
{
  imports = [
    ../web-proxy
  ];

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
    defaultListen = [
      {
        addr = "0.0.0.0";
        ssl = false;
      }
      {
        addr = "0.0.0.0";
        ssl = true;
        proxyProtocol = true;
      }
    ];
    recommendedProxySettings = false;
    # Configure proper client IP handling
    commonHttpConfig = ''
      # Trust proxy protocol for real client IP
      real_ip_header proxy_protocol;
      set_real_ip_from 127.0.0.1;
      set_real_ip_from ::1;

      # Log format to include real client IP
      log_format main '$proxy_protocol_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent"';
    '';
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


