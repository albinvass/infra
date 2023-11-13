{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    cloudflared
  ];
  deployment = {
    keys = {
      "cloudflared-cert.pem" = {
        name = "cert.pem";
        destDir = "/etc/cloudflared";
        keyCommand = ["bws-get" "cloudflare-tunnel-cert"];
        user = "cloudflared";
        group = "cloudflared";
        permissions = "0600";
      };
      "cloudflared-credentials.json" = {
        name = "credentials.json";
        destDir = "/etc/cloudflared";
        keyCommand = [
          "pulumi" "stack" "output"
          "--stack" "albinvass/Hetzner/infra"
          "--show-secrets"
          "devbox-tunnel-credentials"
        ];
        user = "cloudflared";
        group = "cloudflared";
        permissions = "0600";
      };
    };
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "devbox" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        default = "http_status:404";
      };
    };
  };
}
