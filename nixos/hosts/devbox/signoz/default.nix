{ ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "signoz.albinvass.se" = "http://localhost:8081";
  };
  services.signoz-frontend.enable = true;
}
