{ config, lib, pkgs, ... }: {
  imports = [../../modules/development-tools];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.avass = {
    isNormalUser = true;
    home = "/home/avass";
    extraGroups = [ "wheel" ];
  };
  
  environment.systemPackages = with pkgs; [
    cloudflared
  ];

  networking.firewall = {
    enable = true;
  };
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

  services.cloudflared = {
    enable = true;
    tunnels = {
      "devbox" = {
        credentialsFile = "/etc/cloudflared/credentials.json";
        default = "http_status:404";
        ingress = {
          "dev.albinvass.se" = {
            service = "http://localhost:4444";
          };
        };
      };
    };
  };
}
