{ config, pkgs, ...}:
{
  users.users."affine" = {
    name = "affine";
    group = "affine";
    isSystemUser = true;
  };

  users.groups."affine" = {};

  sops.secrets = {
    "affine/cifs" = { };
  };

  albinvass.resticBackup.services.affine = {
    paths = [
      "/var/lib/affine"
      "/opt/affine"
    ];
    exclude = [
      "\#recycle"
    ];
  };

  fileSystems."/var/lib/affine" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "affine";
      group = "affine";
    in [ "${automount_opts},credentials=${config.sops.secrets."affine/cifs".path},uid=${user},gid=${group},nobrl" ];
  };

  services.frp.settings.proxies = [
    {
      name = "HTTP affine.albinvass.se";
      customDomains = ["affine.albinvass.se"];
      type = "http";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultHTTPListenPort;
    }
    {
      name = "HTTPS affine.albinvass.se";
      customDomains = ["affine.albinvass.se"];
      type = "https";
      localIP = config.networking.hostName;
      localPort = config.services.nginx.defaultSSLListenPort;
      transport.proxyProtocolVersion = "v2";
    }
  ];
  services.nginx.virtualHosts = {
    "affine.albinvass.se" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3010";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $proxy_protocol_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_set_header        X-Forwarded-Host $host;
          proxy_set_header        X-Forwarded-Server $host;
        '';
      };
      extraConfig = ''
          client_max_body_size 20000M;
      '';
    };
  };
}
