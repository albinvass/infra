{ pkgs, ... }: {
  sops.secrets = {
    "cloudflared/credentials.json" = {};
    "cloudflared/cert.pam" = {};
  };

  environment.systemPackages = with pkgs; [
    cloudflared
  ];

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
