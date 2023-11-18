{ pkgs, ... }: let 
  clickHousePort = "10000";
  signozListen = {
    addr = "127.0.0.1";
    port = 80;
  };
in {
  services.cloudflared.tunnels.devbox.ingress = {
    "signoz.albinvass.se" = "http://${signozListen.addr}:${builtins.toString signozListen.port}";
  };
  services.nginx.virtualHosts."signoz.albinvass.se" = {
    listen = [signozListen];
    locations = {
      "/".proxyPass = "http://localhost:8081";
      "/api".proxyPass = "http://localhost:8080";
    };
  };
  environment.systemPackages = [
    pkgs.mysql
  ];
  environment.etc."/clickhouse-server/config.d/config.yaml" = {
    text = ''
      tcp_port: ${clickHousePort}
    '';
    user="clickhouse";
    group="clickhouse";
  };
  services.clickhouse.enable = true;
  services.signoz-frontend.enable = true;
  services.signoz-query-service = {
    enable = true;
    clickHouseURL = "tcp://localhost:${clickHousePort}";
    prometheus = {
      global = {
        scrape_interval = "5s";
        evaluation_interval = "15s";
      };
      alerting = {};
      rule_files = [];
      scrape_configs = [];
      remote_read = [{url="tcp://localhost:10000/?database=signoz_metrics";}];
    };
  };
}
