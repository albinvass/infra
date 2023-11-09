{pkgs}: 
{
  meta = {
    nixpkgs = pkgs;
  };

  devbox = {name, nodes, ...}@hetzner-inputs: with hetzner-inputs; {
    imports = hetznerBaseModules ++ [../nixos/hosts/devbox];
    deployment = {
      buildOnTarget = true;
      targetHost = "65.109.130.106";
      targetPort = 22;
      targetUser = "root";
      keys = {
        "cloudflared-cert.pem" = {
          name = "cert.pem";
          destDir = "/etc/cloudflared";
          keyCommand = [
            "./tools/bw-get.py" "attachment" "dash.cloudflare.com" "devbox-cert.pem"
          ];
          user = "cloudflared";
          group = "cloudflared";
          permissions = "0600";
        };
        "cloudflared-credentials.json" = {
          name = "credentials.json";
          destDir = "/etc/cloudflared";
          keyCommand = [
            "./tools/bw-get.py" "field" "dash.cloudflare.com" "devbox tunnel"
          ];
          user = "cloudflared";
          group = "cloudflared";
          permissions = "0600";
        };
      };
    };

    networking.hostName = name;
  };
}
