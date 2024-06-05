{ config, pkgs, ... }: {
  sops.secrets = {
    "haproxy/certs/environmentFile" = {
      owner = config.systemd.services.haproxy.serviceConfig.User;
      group = config.systemd.services.haproxy.serviceConfig.Group;
    };
  };

  services.haproxy = {
    enable = true;
    config = builtins.readFile ./haproxy.conf;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "albinvass@gmail.com";
    certs."test.albinvass.se" = {
      server = ""https://acme-staging-v02.api.letsencrypt.org/directory"";
      dnsProvider = "inwx";
      environmentFile = config.sops.secrets."haproxy/cert/environmentFile".path;
    };
  };
}
