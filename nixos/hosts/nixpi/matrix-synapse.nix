{ config, pkgs, ... }: {
  users = {
    users.matrix-synapse = {
      group = "matrix-synapse";
      isSystemUser = true;
    };
    groups.matrix-synapse = {};
  };
  sops.secrets = {
    "matrix-synapse/cifs" = {
      owner = "matrix-synapse";
      group = "matrix-synapse";
    };
  };

  fileSystems."/var/lib/matrix-synapse" = {
    device = "//storage/matrix-synapse";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.sops.secrets."matrix-synapse/cifs".path}"];
  };
}
