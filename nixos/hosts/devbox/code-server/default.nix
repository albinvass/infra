{ pkgs, ... }: {
  # Needed for code-server
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
  ];

  services.code-server = {
    enable = true;
    host = "0.0.0.0";
    auth = "none";
    user = "avass";
  };

  services.cloudflared.tunnels.devbox.ingress = {
    "code.albinvass.se" = "http://localhost:4444";
  };
}
