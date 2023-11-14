{config, pkgs, lib, ...}:
let
  listenPort = "9000";
  consolePort = "9001";
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
    "s3.albinvass.se" = "http://localhost:${listenPort}";
    "minio.albinvass.se" = "http://localhost:${consolePort}";
  };

  environment.systemPackages = with pkgs; [ minio-client ];
  services.minio = {
    enable = true;
    region = "eu-north-1";
    rootCredentialsFile = "/etc/minio/minio-root-credentials";
    listenAddress = ":${listenPort}";
    consoleAddress = ":${consolePort}";
    dataDir = ["/var/lib/davfs2/minio/data"];
    configDir = "/var/lib/davfs2/minio/config";
  };
}
