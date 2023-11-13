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
        user = "minio";
        group = "minio";
        permissions = "0600";
      };
    };
  };

  services.cloudflared.tunnels.devbox.ingress = {
    "s3.albinvass.se" = "http://${listenAddress}";
    "minio.albinvass.se" = "http://${consoleAddress}";
  };

  environment.systemPackages = with pkgs; [ minio-client ];
  services.minio = {
    enable = true;
    region = "eu-north-1";
    rootCredentialsFile = "/etc/minio/minio-root-credentials";
    listenAddress = listenAddress;
    consoleAddress = consoleAddress;
    dataDir = ["/var/lib/davfs2/minio/data"];
    configDir = "/var/lib/davfs2/minio/config";
  };
}
