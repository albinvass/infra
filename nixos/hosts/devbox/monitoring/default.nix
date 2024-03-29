{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.jdk17_headless ];
  services = {
    cloudflared.tunnels.devbox.ingress = {
      "prometheus.albinvass.se" = "http://localhost:${builtins.toString config.services.prometheus.port}";
      "grafana.albinvass.se" = "http://localhost:${builtins.toString config.services.grafana.settings.server.http_port}";
    };
    prometheus = {
      enable = true;
      stateDir = "prometheus";
      scrapeConfigs =[{
          job_name = "steam-servers";
          static_configs = [{
            targets = [ "steam-servers.dev.albinvass.se:9002" ];
          }];
      }];
    };
    grafana = {
      enable = true;
      settings = {
        server = {
          root_url = "https://grafana.albinvass.se";
        };
      };
    };
  };
}
