{ config, lib, pkgs, vinemetrics-irc, ... }:
{
  virtualisation.oci-containers.containers = {
    zuul-web = {
      image = "zuul/zuul-web";
    };
  };
}
