{ config, pkgs, ...}:
{
  users.users."immich" = {
    name = "immich";
    group = "immich";
    isSystemUser = true;
  };

  users.groups."immich" = {};

  sops.secrets = {
    "immich/cifs" = { };
  };

  albinvass.resticBackup.services.immich = {
    paths = [
      "/var/lib/immich"
      "/opt/immich"
    ];
    exclude = [
      "\#recycle"
    ];
  };

  fileSystems."/var/lib/immich" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "immich";
      group = "immich";
    in [ "${automount_opts},credentials=${config.sops.secrets."immich/cifs".path},uid=${user},gid=${group}" ];
  };

  albinvass.webProxy.services = {
    "immich.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = 2283;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };
}
