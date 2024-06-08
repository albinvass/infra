{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "albinvass@gmail.com";
  };
  services.nginx = {
    enable = true;
    virtualHosts = {
      "test.albinvass.se" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8082";
          };
        };
      };
      "storage.albinvass.se" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
