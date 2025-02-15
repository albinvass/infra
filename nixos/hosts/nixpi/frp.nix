{ config, ... }:

{
  sops.secrets = {
    "frp/tls/certFile" = { };
    "frp/tls/keyFile" = { };
    "frp/tls/trustedCaFile" = { };
  };

  systemd.services.frp.serviceConfig = {
    LoadCredential = [
      "certFile:${config.sops.secrets."frp/tls/certFile".path}"
      "keyFile:${config.sops.secrets."frp/tls/keyFile".path}"
      "trustedCaFile:${config.sops.secrets."frp/tls/trustedCaFile".path}"
    ];
  };
  services.frp = {
    enable = true;
    role = "client";
    settings = {
      serverAddr = "reverse-proxy.albinvass.se";
      serverPort = 7000;
      transport = {
        tls = {
          certFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/certFile";
          keyFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/keyFile";
          trustedCaFile = "{{ .Envs.CREDENTIALS_DIRECTORY }}/trustedCaFile";
        };
      };
      proxies = [
        {
          name = "attic.albinvass.se";
          type = "tcp";
          remotePort = 8082;
          localIP = "127.0.0.1";
          localPort = 8080;
        }
        {
          name = "storage.albinvass.se";
          type = "tcp";
          remotePort = 8083;
          localIP = "storage.";
          localPort = 5000;
        }
        {
          name = "zuul.albinvass.se";
          type = "tcp";
          remotePort = 8084;
          localIP = "127.0.0.1";
          localPort = 9000;
        }
        {
          name = "jellyfin.albinvass.se";
          type = "tcp";
          remotePort = 8085;
          localIP = "192.168.50.131";
          localPort = 8096;
        }
        {
          name = "jellyseer.albinvass.se";
          type = "tcp";
          remotePort = 8086;
          localIP = "192.168.50.131";
          localPort = 5055;
        }
        {
          name = "immich.albinvass.se";
          type = "tcp";
          remotePort = 8087;
          localIP = "192.168.50.131";
          localPort = 2283;
        }
        {
          name = "nextcloud.albinvass.se";
          type = "tcp";
          remotePort = 8088;
          localIP = "192.168.50.131";
          localPort = 8081;
        }
        {
          name = "collabora.albinvass.se";
          type = "tcp";
          remotePort = 8089;
          localIP = "192.168.50.131";
          localPort = 9980;
        }
        {
          name = "joplin.albinvass.se";
          type = "tcp";
          remotePort = 8090;
          localIP = "192.168.50.131";
          localPort = 22300;
        }
        {
          name = "navidrome.albinvass.se";
          type = "tcp";
          remotePort = 8091;
          localIP = "192.168.50.131";
          localPort = 4533;
        }
        {
          name = "audiobookshelf.albinvass.se";
          type = "tcp";
          remotePort = 8092;
          localIP = "192.168.50.131";
          localPort = 13378;
        }
      ];
    };
  };
}
