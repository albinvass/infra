{ config, inputs, ... }:
{
  imports = [ inputs.attic.nixosModules.atticd ];
  sops.secrets = {
    "attic/credentialsFile" = {
      # owner = config.services.atticd.user;
      # inherit (config.services.atticd) group;
    };
  };

  services.atticd = {
    enable = true;
    credentialsFile = config.sops.secrets."attic/credentialsFile".path;
    settings = {
      listen = "127.0.0.1:8080";
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
}
