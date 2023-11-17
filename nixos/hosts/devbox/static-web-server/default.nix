{ lib, ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "albinvass.se" = "http://localhost:8787";
  };
  environment.etc."/static-web-server/index.html" = {
    text = ''Welcome!'';
    user = "static-web-server";
    group = "static-web-server";
  };
  services.static-web-server = {
    enable = true;
    root = "/etc/static-web-server/";
  };
}
