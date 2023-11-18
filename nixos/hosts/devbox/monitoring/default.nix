{ config, ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "prometheus.albinvass.se" = "http://localhost:${builtins.toString config.services.prometheus.port}";
    "elastic.albinvass.se" = "http://localhost:${builtins.toString config.services.elasticsearch.port}";
    "grafana.albinvass.se" = "http://localhost:${builtins.toString config.services.grafana.settings.server.http_port}";
  };
  services.prometheus = {
    enable = true;
    stateDir = "prometheus";
  };
  services.elasticsearch = {
    enable = true;
  };
  services.grafana = {
    enable = true;
    settings = {
      server = {
        root_url = "https://grafana.albinvass.se";
      };
    };
  };
}
