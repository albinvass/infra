{ config, pkgs, ... }: {
  sops.secrets = {
    "cloudflared/credentials.json" = {
      owner = "cloudflared";
      group = "cloudflared";
      restartUnits = [ "cloudflared-tunnel-nixpi.service" ];
    };
    "cloudflared/cert.pem" = {
      owner = "cloudflared";
      group = "cloudflared";
      path = "/etc/cloudflared/cert.pem";
      restartUnits = [ "cloudflared-tunnel-nixpi.service" ];
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  services.cloudflared = {
    enable = true;
    tunnels = {
      nixpi = {
        credentialsFile = config.sops.secrets."cloudflared/credentials.json".path;
        default = "http_status:404";
        ingress = {
          "nixpi-ssh.albinvass.se" = "ssh://localhost:22";
        };
        ingress = {
          "storage.albinvass.se" = "http://synologynas:5000";
        };
      };
    };
  };
}
