{ config, ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "matrix.albinvass.se" = "http://localhost:8008";
  };
  fileSystems."/var/lib/synapse" = {
    device = "/dev/data/synapse";
    fsType = "ext4";
  };

  sops.secrets = {
    "matrix-synapse/signing-key" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0600";
      restartUnits = [ "matrix-synapse.service" ];
    };
    "matrix-synapse/extraConfSecrets.yaml" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0600";
      restartUnits = [ "matrix-synapse.service" ];
    };
  };

  environment.etc."/static-web-server/.well-known/matrix/server" = {
    mode = "0755";
    text = builtins.toJSON {
      "m.server" = "matrix.albinvass.se:443";
    };
  };

  services.matrix-synapse = {
    enable = true;
    dataDir = "/var/lib/synapse/data";
    settings = {
      server_name = "albinvass.se";
      enable_metrics = true;
      signing_key_path = config.sops.secrets."matrix-synapse/signing-key".path;
      listeners = [
        {
          port = 8008;
          bind_addresses = ["127.0.0.1"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [{
            names = [ "client" "federation" ];
            compress = true;
          }];
        }
        {
          port = 9002;
          type = "metrics";
          bind_addresses = ["127.0.0.1"];
        }
      ];
      database.name = "sqlite3";

    };
    extraConfigFiles = [
      config.sops.secrets."matrix-synapse/extraConfSecrets.yaml".path
    ];
  };
}


