{
  config,
  lib,
  ...
}:
let
  actualPort = "5006";
in
{
  users.users."actual" = {
    name = "actual";
    group = "actual";
    isSystemUser = true;
  };

  users.groups."actual" = { };

  sops.secrets = {
    "actual/cifs" = { };

    "actual/environmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };

  };

  virtualisation.oci-containers.containers = {
    "actual" = {
      image = "actualbudget/actual-server@sha256:6e64dab321cd0cde89b6a8fefe92dd2f083c6e0f58139c03dc4cf2c8902657a3";
      user = "983";
      ports = [
        "${actualPort}:${actualPort}"
      ];
      volumes = [
        "/var/lib/actual:/data"
      ];
      environmentFiles = [
        config.sops.secrets."actual/environmentFile".path
      ];
    };
  };

  albinvass.resticBackup.services.actual = {
    paths = [
      "/var/lib/actual"
    ];
    exclude = [
      "\#recycle"
    ];
  };

  fileSystems."/var/lib/actual" = {
    device = "//storage./home";
    fsType = "cifs";
    options =
      let
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
        user = "actual";
        group = "actual";
      in
      [
        "${automount_opts},credentials=${
          config.sops.secrets."actual/cifs".path
        },uid=${user},gid=${group},nobrl"
      ];
  };

  albinvass.webProxy.services = {
    "actual.albinvass.se" = {
      backend = {
        host = "127.0.0.1";
        port = lib.toInt actualPort;
      };
      ssl = true;
      websockets = true;
      clientMaxBodySize = "20000M";
    };
  };
}

