{ config, lib, pkgs, vinemetrics-irc, ... }:
{
  containers.zookeeper-1 = {
    autoStart = true;
    config =
      { config, pkgs, ...}:
      {
        services.zookeeper = {
          enable = true;
          id = 0;
          dataDir = "/var/lib/zookeeper/data";
          extraConf = builtins.readFile ./zoo.cfg;
          extraCmdLineOptions = [
            "-Dzookeeper.datadir.autocreate=true"
          ];
          logging = builtins.readFile ./log.cfg;
        };
        networking.firewall.allowedTCPPorts = [ 2181 ];
      };
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
  };
}
