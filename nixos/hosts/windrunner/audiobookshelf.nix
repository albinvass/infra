{ config, ... }:
{
  sops.secrets = {
    "audiobookshelf/cifs" = { };
  };

  albinvass.resticBackup.services.audiobookshelf = {
    paths = [ "/var/lib/audiobookshelf" ];
    backupPrepareCommand = "systemctl stop audiobookshelf";
    backupCleanupCommand = "systemctl start audiobookshelf";
    useRunitor = false;
  };

  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
    port = 8001;
  };
  systemd.services.audiobookshelf.serviceConfig = {
    RequiresMountsFor = "/var/lib/audiobookshelf/data";
  };
  fileSystems."/var/lib/audiobookshelf/data" = {
    device = "//storage./home/audiobooks";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
        inherit (config.services.audiobookshelf) user;
        inherit (config.services.audiobookshelf) group;
      in
      [
        "${automount_opts},credentials=${
          config.sops.secrets."audiobookshelf/cifs".path
        },uid=${user},gid=${group}"
      ];
  };

  albinvass.webProxy.services = {
    "audiobookshelf.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = 8001;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "5000M";
    };
  };
}
