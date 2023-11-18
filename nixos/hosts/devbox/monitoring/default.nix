{ config, ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "prometheus.albinvass.se" = "http://localhost:${config.services.prometheus.port}";
    "elastic.albinvass.se" = "http://localhost:${config.services.elasticsearch.port}";
    "grafana.albinvass.se" = "http://localhost:${config.services.grafana.settings.http_port}";
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
  };
}
