{ config, lib, pkgs, ... }: {
  imports = [../../modules/development-tools];
  
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 4444 ];
  };
  # Needed for code-server
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
  ];

  services.code-server = {
    enable = true;
    host = "0.0.0.0";
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "devbox" = {
        credentialsFile = "/etc/cloudflared/cloudflared-credentials";
        default = "http_status:404";
        ingress = {
          "dev.albinvass.se" = {
            service = "http://localhost:4444";
          };
        };
      };
    };
  };
}
