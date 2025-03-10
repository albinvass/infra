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
    "matrix-synapse/restic/passwordFile" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0600";
    };
    "matrix-synapse/restic/repositoryFile" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0600";
    };
    "matrix-synapse/restic/environmentFile" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
      mode = "0600";
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

  services.restic.backups.matrix-synapse = {
    initialize = true;
    passwordFile = config.sops.secrets."matrix-synapse/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."matrix-synapse/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."matrix-synapse/restic/environmentFile".path;
    paths = [ config.services.matrix-synapse.dataDir ];
    backupPrepareCommand = "systemctl stop matrix-synapse";
    backupCleanupCommand = "systemctl start matrix-synapse";
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
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
}
