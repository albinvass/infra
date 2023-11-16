{ lib, ... }: {
  services.cloudflared.tunnels.devbox.ingress = {
    "matrix.albinvass.se" = "http://localhost:8008";
  };
  fileSystems."/var/lib/synapse" = {
    device = "/dev/data/synapse";
    fsType = "ext4";
  };
  deployment = {
    keys = {
      "matrix-synapse-signing-key" = {
        name = "matrix.albinvass.se.signing.key";
        destDir = "/etc/matrix-synapse/keys";
        keyCommand = ["bws-get" "matrix-synapse-signing-key"];
        user = "matrix-synapse";
        group = "matrix-synapse";
        permissions = "0600";
      };
      "matrix-synapse-secrets" = {
        name = "secrets";
        destDir = "/etc/matrix-synapse";
        keyCommand = ["bws-get" "matrix-synapse-secrets"];
        user = "matrix-synapse";
        group = "matrix-synapse";
        permissions = "0600";
      };
    };
  };
  services.matrix-synapse = {
    enable = true;
    dataDir = "/var/lib/synapse/data";
    settings = {
      server_name = "matrix.albinvass.se";
      signing_key_path = "/etc/matrix-synapse/keys/matrix.albinvass.se.signing.key";
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
      ];
      database.name = "sqlite3";

    };
    extraConfigFiles = [
      "/etc/matrix-synapse/secrets"
    ];
  };
}


