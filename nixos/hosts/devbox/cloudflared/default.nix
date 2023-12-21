{ config, pkgs, ... }: {
  sops.secrets = {
    "cloudflared/credentials.json" = {
      owner = "cloudflared";
      group = "cloudflared";
      restartUnits = [ "cloudflared-tunnel-devbox.service" ];
    };
    "cloudflared/cert.pem" = {
      owner = "cloudflared";
      group = "cloudflared";
      path = "/etc/cloudflared/cert.pem";
      restartUnits = [ "cloudflared-tunnel-devbox.service" ];
    };
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  services.cloudflared = {
    enable = true;
    tunnels = {
      "devbox" = {
        credentialsFile = config.sops.secrets."cloudflared/credentials.json".path;
        default = "http_status:404";
      };
    };
  };
}
