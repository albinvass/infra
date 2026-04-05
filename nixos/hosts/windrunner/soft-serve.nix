{ ... }:
{

  virtualisation.oci-containers.containers = {
    "soft-serve" = {
      # v0.11.6: sha256:7742f301ab4e5c24eccf999b10aabb97ec64e18c23f693a16599071d49ae5bf4
      image = "docker.io/charmcli/soft-serve@sha256:7742f301ab4e5c24eccf999b10aabb97ec64e18c23f693a16599071d49ae5bf4";
      ports = [
        "23231:23231"
        "23232:23232"
      ];
      volumes = [
        "/var/lib/soft-serve:/soft-serve"
      ];
      environment = {
        SOFT_SERVE_INITIAL_ADMIN_KEYS = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDxPbSId6SM81tiIv8pLpZwOkJYVmF8EOlv9EHUJ9J5hAAAABHNzaDo= ssh:";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [
    23231
    23232
  ];

  albinvass.resticBackup.services.audiobookshelf = {
  };

  albinvass.resticBackup.services.soft-serve = {
    paths = [ "/var/lib/soft-serve" ];
    backupPrepareCommand = "systemctl stop podman-soft-serve";
    backupCleanupCommand = "systemctl start podman-soft-serve";
    useRunitor = false;
  };
}
