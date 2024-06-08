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
    virtualHosts = let
      hostDefaults = {
        forceSSL = true;
        enableACME = true;
      };
      frpProxies = lib.attrsets.mergeAttrsList (map (node: with nodes.${node}.config.services.frp;
        if builtins.hasAttr "proxies" settings
        then builtins.listToAttrs(map (proxy: { name = "${proxy.name}"; value = hostDefaults // {
          locations = {
            "/" = {
              proxyPass = "http://127.0.0.1:${builtins.toString proxy.remotePort}";
            };
          };
        };}) settings.proxies)
        else {}
      ) (builtins.attrNames nodes));

    in frpProxies;
  };
}
