{ config, ... }:
{
  sops.secrets = {
    "healthchecks/SECRET_KEY_FILE" = {
      owner = config.services.healthchecks.user;
      group = config.services.healthchecks.group;
      mode = "0600";
    };
  };

  services.healthchecks = {
    enable = true;
    settings = {
      SECRET_KEY_FILE = config.sops.secrets."healthchecks/SECRET_KEY_FILE".path;
      SITE_ROOT = "https://healthchecks.albinvass.se";
    };
  };

  albinvass.resticBackup.services.healthchecks = {
    paths = [ "/var/lib/healthchecks" ];
    backupPrepareCommand = "systemctl stop healthchecks";
    backupCleanupCommand = "systemctl start healthchecks";
  };

  albinvass.webProxy.services."healthchecks.albinvass.se" = {
    backend = {
      host = "127.0.0.1";
      port = 8000;
    };
    ssl = true;
    websockets = true;
  };
}
