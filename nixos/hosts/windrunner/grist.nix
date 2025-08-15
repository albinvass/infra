{ config, pkgs, lib, ...}:
let
  gristPort = "8484";
in
{
  users.users."grist" = {
    name = "grist";
    group = "grist";
    isSystemUser = true;
  };

  users.groups."grist" = {};

  sops.secrets = {
    "grist/cifs" = { };

    "grist/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };

  };

  virtualisation.oci-containers.containers = {
    "grist" = {
      image = "docker.io/gristlabs/grist:1.6.1";
      user = "988";
      ports = [
        "${gristPort}:${gristPort}"
      ];
      volumes = [
        "/var/lib/grist:/persist"
      ];
      environment = {
        GRIST_SANDBOX_FLAVOR= "gvisor";
      };
      environmentFiles = [
        config.sops.secrets."grist/environmentFile".path
      ];
    };
  };

  albinvass.resticBackup.services.grist = {
    paths = [
      "/var/lib/grist"
    ];
    exclude = [
      "\#recycle"
    ];
  };

  fileSystems."/var/lib/grist" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "grist";
      group = "grist";
    in [ "${automount_opts},credentials=${config.sops.secrets."grist/cifs".path},uid=${user},gid=${group},nobrl" ];
  };

  albinvass.webProxy.services = {
    "grist.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = lib.toInt gristPort;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };
}
