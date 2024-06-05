{ ... }: {
  networking.firewall.allowedTCPPorts = [ 443 80 ];

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
      };
    };
  };
}
