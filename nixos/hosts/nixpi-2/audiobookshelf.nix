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

  services.frp.settings.proxies = [
    {
      name = "HTTP audiobookshelf.albinvass.se";
      customDomains = ["audiobookshelf.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS audiobookshelf.albinvass.se";
      customDomains = ["audiobookshelf.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
    }
  ];
  services.nginx.virtualHosts = {
    "audiobookshelf.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8000";
        proxyWebsockets = true;
      };
      extraConfig = ''
          client_max_body_size 5000M;
      '';
    };
  };
}
