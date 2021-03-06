{ config, lib, pkgs, vinemetrics-irc, ... }:
{
  containers.mysql = {
    autoStart = true;
    config =
      { config, pkgs, ...}:
      {
        services.mysql = {
          enable = true;
          package = pkgs.mariadb;
          ensureUsers = [
            {
              name = "zuul";
              ensurePermissions = {
                "zuul.*" = "ALL PRIVILEGES";
              };
            }
          ];
          ensureDatabases = [ "zuul" ];
        };
        networking.firewall.allowedTCPPorts = [ 3306 ];
      };
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.12";
  };
}
