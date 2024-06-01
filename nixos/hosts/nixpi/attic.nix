{ config, inputs, ...}:
{
  imports = [
    inputs.attic.nixosModules.atticd
  ];
  sops.secrets = {
    "attic/credentialsFile" = {
      owner = config.services.atticd.user;
      inherit (config.services.atticd) group;
    };
  };

  services.cloudflared = {
    tunnels = {
      nixpi = {
        ingress = {
          "attic.albinvass.se" = "http://localhost:8080";
        };
      };
    };
  };

  services.atticd = {
    enable = true;
    credentialsFile = config.sops.secrets."attic/credentialsFile".path;
    settings = {
      listen = "localhost:8080";
      chunking = {
        nar-size-threshold = 64 * 1024; # 64 KiB
        min-size = 16 * 1024; # 16 KiB
        avg-size = 64 * 1024; # 64 KiB
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
}
