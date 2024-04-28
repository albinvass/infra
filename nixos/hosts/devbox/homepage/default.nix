{ config, ... }:
{
  services.cloudflared.tunnels.devbox.ingress = {
    "homepage.albinvass.se" = "http://localhost:${builtins.toString config.services.homepage-dashboard.listenPort}";
  };
  services.homepage-dashboard = {
    enable = true;
  };
}
