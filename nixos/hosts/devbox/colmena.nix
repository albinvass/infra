{name, nodes, hetznerBaseModules }: {
  imports = hetznerBaseModules ++ [./default.nix];
  deployment = {
    buildOnTarget = true;
    targetHost = "65.108.153.140";
    targetPort = 22;
    targetUser = "root";
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

  networking.hostName = name;
}
