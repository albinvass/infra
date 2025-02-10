{ nodes, lib, ... }:
{
  networking.firewall.allowedTCPPorts = [
    443
    80
  ];

  security.acme = {
    acceptTerms = true;
    defaults.email = "albinvass@gmail.com";
  };
  services.nginx = {
    enable = true;
    virtualHosts =
      let
        hostDefaults = {
          forceSSL = true;
          enableACME = true;
        };
        serverConfigs = {
          "immich.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "media.albinvass.se" = {};
          "media-requests.albinvass.se" = {};
          "nextcloud.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "storage.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "attic.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
        };
        frpProxies = lib.attrsets.mergeAttrsList (
          map (
            node:
            with nodes.${node}.config.services.frp;
            if builtins.hasAttr "proxies" settings then
              builtins.listToAttrs (
                map (proxy: {
                  name = "${proxy.name}";
                  value = hostDefaults // {
                    locations = {
                      "/" = {
                        proxyPass = "http://127.0.0.1:${builtins.toString proxy.remotePort}";
                      };
                    };
                  } // (if builtins.hasAttr proxy.name serverConfigs then
                        serverConfigs.${proxy.name}
                       else {});
                }) settings.proxies
              )
            else
              { }
          ) (builtins.attrNames nodes)
        );
      in
      frpProxies;
  };
}
