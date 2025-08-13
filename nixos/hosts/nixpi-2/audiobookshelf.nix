{ config, ... }: {
  sops.secrets = {
    "cifs" = { };

    "audiobookshelf/restic/passwordFile" = {
      owner = "audiobookshelf";
      group = "audiobookshelf";
      mode = "0600";
    };
    "audiobookshelf/restic/repositoryFile" = {
      owner = "audiobookshelf";
      group = "audiobookshelf";
      mode = "0600";
    };
    "audiobookshelf/restic/environmentFile" = {
      owner = "audiobookshelf";
      group = "audiobookshelf";
      mode = "0600";
    };
  };

  services.restic.backups.audiobookshelf = {
    initialize = true;
    passwordFile = config.sops.secrets."audiobookshelf/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."audiobookshelf/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."audiobookshelf/restic/environmentFile".path;
    paths = [ "/var/lib/audiobookshelf" ];
    backupPrepareCommand = "systemctl stop audiobookshelf";
    backupCleanupCommand = "systemctl start audiobookshelf";
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
  };

  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };
  systemd.services.audiobookshelf.serviceConfig = {
    RequiresMountsFor="/var/lib/audiobookshelf/data";
  };
  fileSystems."/var/lib/audiobookshelf/data" = {
    device = "//storage./home/audiobooks";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      inherit (config.services.audiobookshelf) user;
      inherit (config.services.audiobookshelf) group;
    in [ "${automount_opts},credentials=${config.sops.secrets."cifs".path},uid=${user},gid=${group}" ];
  };

  services.webProxy.services = {
    "audiobookshelf.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = 8000;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "5000M";
    };
  };
}
