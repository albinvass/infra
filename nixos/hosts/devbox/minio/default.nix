{config, pkgs, ...}:
let
  listenPort = "9000";
  consolePort = "9001";
in {

  sops.secrets = {
    "minio/root-credentials" = {
      owner = "minio";
      group = "minio";
      mode = "0600";
      restartUnits = [ "minio.service" ];
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
    rootCredentialsFile = config.sops.secrets."minio/root-credentials".path;
    listenAddress = ":${listenPort}";
    consoleAddress = ":${consolePort}";
    dataDir = ["/var/lib/davfs2/minio/data"];
    configDir = "/var/lib/davfs2/minio/config";
  };
}
