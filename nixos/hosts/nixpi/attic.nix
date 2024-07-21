{ config, lib, inputs, ... }:
let
  atticUser = "atticd";
in {
  imports = [ inputs.attic.nixosModules.atticd ];
  sops.secrets = {
    "attic/credentialsFile" = {
      # owner = config.services.atticd.user;
      # inherit (config.services.atticd) group;
    };
  };

  users = {
    users.${atticUser} = {
      group = atticUser;
      isSystemUser = true;
    };
    groups.${atticUser} = {};
  };

  systemd.services.atticd.serviceConfig = {
    StateDirectory = lib.mkForce null;
    ReadWritePaths = lib.mkForce [ (builtins.dirOf config.services.atticd.settings.storage.path) ];
  };
  services.atticd = {
    enable = true;
    user = atticUser;
    credentialsFile = config.sops.secrets."attic/credentialsFile".path;
    settings = {
      listen = "127.0.0.1:8080";
      database = {};
      api-endpoint = "https://attic.albinvass.se/";
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
  fileSystems."${builtins.dirOf config.services.atticd.settings.storage.path}" = {
    device = "storage:/volume1/attic";
    fsType = "nfs";
  };
}
