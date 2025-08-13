{ config, pkgs, ...}:
{
  users.users."immich" = {
    name = "immich";
    group = "immich";
    isSystemUser = true;
  };

  users.groups."immich" = {};

  sops.secrets = {
    "immich/cifs" = { };

    "immich/restic/passwordFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "immich/restic/repositoryFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "immich/restic/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  services.restic.backups.immich = {
    initialize = true;
    package =
      let
        runitorWrappedRestic = pkgs.writeShellScriptBin "restic"
          ''
            #!${pkgs.bash}/bin/bash
            ${pkgs.runitor}/bin/runitor -- ${pkgs.restic}/bin/restic "$@"
          '';
      in runitorWrappedRestic;
    passwordFile = config.sops.secrets."immich/restic/passwordFile".path;
    repositoryFile = config.sops.secrets."immich/restic/repositoryFile".path;
    environmentFile = config.sops.secrets."immich/restic/environmentFile".path;
    paths = [
      "/var/lib/immich"
      "/opt/immich"
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

  fileSystems."/var/lib/immich" = {
    device = "//storage./home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user = "immich";
      group = "immich";
    in [ "${automount_opts},credentials=${config.sops.secrets."immich/cifs".path},uid=${user},gid=${group}" ];
  };

  services.webProxy.services = {
    "immich.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = 2283;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };
}
