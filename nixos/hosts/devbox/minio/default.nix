{config, pkgs, lib, ...}:
let
  listenAddress = "localhost:9000";
  consoleAddress = "localhost:9001";
in rec {
  deployment = {
    keys = {
      "minio-root-credentials" = {
        destDir = "/etc/minio";
        keyCommand = ["bws-get" "minio-root-credentials"];
        user = "root";
        group = "root";
        permissions = "0600";
      };
    };
  };

  services.cloudflared.tunnels.devbox.ingress = {
    "s3.albinvass.se" = "http://${listenAddress}";
    "minio.albinvass.se" = "http://${consoleAddress}";
  };

  containers.minio = {
    autoStart = true;
    bindMounts = {
      "/etc/minio" = {
        hostPath = "/etc/minio";
        isReadOnly = true;
      };
      "/var/lib/minio" = {
        hostPath = "/var/lib/davfs2/minio";
        isReadOnly = false;
      };
    };
    config = { config, pkgs, lib, ...}: {
      services.minio = {
        enable = true;
        region = "eu-north-1";
        listenAddress = listenAddress;
        consoleAddress = consoleAddress;
      };
    };
  };
}
