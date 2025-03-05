{ config, ... }: {
  sops.secrets = {
    "cifs" = { };
  };

  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };
  systemd.services.audiobookshelf.serviceConfig = {
    RequiresMountsFor="/var/lib/audiobookshelf";
  };
  fileSystems."/var/lib/audiobookshelf/data" = {
    device = "//storage./home/audiobooks";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user=config.services.audiobookshelf.user;
      group=config.services.audiobookshelf.group;
      in [ "${automount_opts},credentials=${config.sops.secrets."cifs".path},uid=${user},gid=${group}" ];
  };
}
