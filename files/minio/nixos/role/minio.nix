{config, pkgs, lib, ...}:
{
  networking.firewall.allowedTCPPorts = [ 9001 9000 ];
  virtualisation.oci-containers.containers = {
    minio = {
      cmd = [
        "server"
        "--address"
        ":9000"
        "--console-address"
        ":9001"
      ];
      image = "quay.io/minio/minio:RELEASE.2023-03-24T21-41-23Z";
      ports = [ "9001:9001" "9000:9000" ];
      environmentFiles = [
        "/etc/minio/minio-root-credentials"
      ];
      environment = {
        MINIO_VOLUMES = "/var/lib/minio";
        MINIO_SERVER_URL = "https://s3.vassast.org";
        MINIO_BROWSER_REDIRECT_URL = "https://minio.vassast.org";
      };
      volumes = [
        "/var/lib/minio:/var/lib/minio"
      ];
    };
  };
}
