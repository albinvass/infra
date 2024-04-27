{ config, pkgs, inputs, ... }: {
  environment.systemPackages = [ pkgs.jdk17_headless ];
  services = {
    cloudflared.tunnels.devbox.ingress = {
      "prometheus.albinvass.se" = "http://localhost:${builtins.toString config.services.prometheus.port}";
      "grafana.albinvass.se" = "http://localhost:${builtins.toString config.services.grafana.settings.server.http_port}";
    };
    prometheus = {
      enable = true;
      stateDir = "prometheus";
      ruleFiles = [
        "${inputs.matrix-synapse}/contrib/prometheus/synapse-v2.rules"
      ];
      scrapeConfigs =[
        {
            job_name = "steam-servers";
            static_configs = [{
              targets = [ "steam-servers.dev.albinvass.se:9002" ];
            }];
        }
        {
            job_name = "matrix-synapse";
            static_configs = [{
              targets = [ "localhost:9002" ];
            }];
        }
      ];
    };
    grafana = {
      enable = true;
      provision = {
        dashboards.settings = {
          apiVersion = 1;
          providers = [{
              name = "default";
              options.path = "${inputs.matrix-synapse}/contrib/grafana";
          }];
        };
      };
      settings = {
        server = {
          root_url = "https://grafana.albinvass.se";
        };
      };
    };
  };
}
