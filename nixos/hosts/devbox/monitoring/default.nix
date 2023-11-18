{ config, ... }: {
  services = {
    cloudflared.tunnels.devbox.ingress = {
      "prometheus.albinvass.se" = "http://localhost:${builtins.toString config.services.prometheus.port}";
      "elastic.albinvass.se" = "http://localhost:${builtins.toString config.services.elasticsearch.port}";
      "grafana.albinvass.se" = "http://localhost:${builtins.toString config.services.grafana.settings.server.http_port}";
      "kibana.albinvass.se" = "http://localhost:${builtins.toString config.services.kibana.port}";
    };
    prometheus = {
      enable = true;
      stateDir = "prometheus";
    };
    elasticsearch = {
      enable = true;
      extraConf = ''
        xpack.security.enabled: true
        xpack.security.authc.api_key.enabled: true
      '';
    };
    kibana = {
      enable = true;
      elasticsearch = {
        certificateAuthorities = [];
        ca = null;
      };
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
