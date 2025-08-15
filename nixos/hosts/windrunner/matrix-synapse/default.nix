{ config, ... }:
{
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

  users.users.matrix-synapse = {
    isSystemUser = true;
    group = "matrix-synapse";
  };
  users.groups.matrix-synapse = {};

  environment.etc."/static-web-server/.well-known/matrix/server" = {
    mode = "0755";
    text = builtins.toJSON { "m.server" = "matrix.albinvass.se:443"; };
  };

  albinvass.resticBackup.services.matrix-synapse = {
    paths = [ config.services.matrix-synapse.dataDir ];
    backupPrepareCommand = "systemctl stop matrix-synapse";
    backupCleanupCommand = "systemctl start matrix-synapse";
    useRunitor = false;
  };

  services.matrix-synapse = {
    enable = true;
    dataDir = "/var/lib/synapse/data";
    settings = {
      server_name = "albinvass.se";
      public_baseurl = "https://matrix.albinvass.se";
      enable_metrics = true;
      signing_key_path = config.sops.secrets."matrix-synapse/signing-key".path;
      listeners = [
        {
          port = 8008;
          bind_addresses = [ "127.0.0.1" ];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [
            {
              names = [
                "client"
                "federation"
              ];
              compress = true;
            }
          ];
        }
        {
          port = 9002;
          type = "metrics";
          tls = false;
          bind_addresses = [ "127.0.0.1" ];
          resources = [ ];
        }
      ];
      database.name = "sqlite3";
    };
    extraConfigFiles = [ config.sops.secrets."matrix-synapse/extraConfSecrets.yaml".path ];
  };

  albinvass.webProxy.services."matrix.albinvass.se" = {
    backend = {
      host = "localhost";
      port = 8008;
    };
    ssl = true;
    websockets = false;
    clientMaxBodySize = "5000M";
  };
}
