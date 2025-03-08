{ nodes, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    8443
    8080
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "letsencrypt.org@mail.albinvass.com";
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    defaultSSLListenPort = 8443;
    defaultHTTPListenPort = 8080;
    virtualHosts = {
      "audiobookshelf.albinvass.se" = {
        #forceSSL = true;
        #enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8000";
          proxyWebsockets = true;
        };
        extraConfig = ''
          client_max_body_size 5000M;
        '';
      };
    };
  };
}

