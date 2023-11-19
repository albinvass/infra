{ lib, config, ... }:
{
  services.cloudflared.tunnels.devbox.ingress = {
    "albinvass.se" = "http://localhost:8787";
  };
  environment.etc."/static-web-server/index.html" = {
    text = let
      sites = builtins.attrNames config.services.cloudflared.devbox.ingress;
      links = builtins.map (f: "<li><a href ${f}>${f}</a></li>") sites;
      body = builtins.concatStringsSep "\n" links;
    in ''
    <html>
    <div> Welcome! </div>
    <ul>
    ${links}
    </ul>
    <html>
    '';
    user = "static-web-server";
    group = "static-web-server";
  };
  services.static-web-server = {
    enable = true;
    root = "/etc/static-web-server/";
  };
}
