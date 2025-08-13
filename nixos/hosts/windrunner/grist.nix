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

    "grist/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "grist/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "grist/restic/environmentFile" = {
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

  services.restic.backups.grist = {
    initialize = true;
    package =
      let
        runitorWrappedRestic = pkgs.writeShellScriptBin "restic"
          ''
            #!${pkgs.bash}/bin/bash
            ${pkgs.runitor}/bin/runitor -- ${pkgs.restic}/bin/restic "$@"
          '';
      in runitorWrappedRestic;
    passwordFile = config.sops.secrets."grist/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."grist/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."grist/restic/environmentFile".path;
    paths = [
      "/var/lib/grist"
    ];
    exclude = [
      "\#recycle"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
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

  services.webProxy.services = {
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
