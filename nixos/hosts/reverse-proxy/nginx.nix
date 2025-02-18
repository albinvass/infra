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
    recommendedProxySettings = true;
    virtualHosts =
      let
        hostDefaults = {
          forceSSL = true;
          enableACME = true;
        };
        serverConfigs = {
          "audiobookshelf.albinvass.se" = {};
          "calibre.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "immich.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "joplin.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 500M;
            '';
          };
          "jellyfin.albinvass.se" = {};
          "jellyseerr.albinvass.se" = {};
          "navidrome.albinvass.se" = {};
          "nextcloud.albinvass.se" = {
            extraConfig = ''
              client_max_body_size 5000M;
            '';
          };
          "collabora.albinvass.se" = {
            locations."/" = {
              proxyWebsockets = true;
            };
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
                  value = (lib.recursiveUpdate hostDefaults (lib.recursiveUpdate {
                    locations = {
                      "/" = {
                        proxyPass = "http://127.0.0.1:${builtins.toString proxy.remotePort}";
                      };
                    };
                  } (if builtins.hasAttr proxy.name serverConfigs then
                        serverConfigs.${proxy.name}
                       else {})));
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
