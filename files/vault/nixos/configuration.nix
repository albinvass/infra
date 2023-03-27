{ config, pkgs, lib, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./site.nix
    ]  ++ lib.optional (builtins.pathExists ./role) ./role;

  networking.hostName = "vault";
  networking.nameservers = ["192.168.1.1"];
  networking.enableIPv6 = false;
  networking.defaultGateway.address = "192.168.1.1";
  networking.interfaces.ens18.useDHCP = true;
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "192.168.1.102";
    prefixLength = 24;
  }];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.version = 2;
  system.stateVersion = "23.05"; # Did you read the comment?
}
