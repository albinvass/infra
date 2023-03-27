{config, pkgs, lib, ...}:
{
  services.dockerRegistry.enable = true;
  services.dockerRegistry.listenAddress = "0.0.0.0";
}

