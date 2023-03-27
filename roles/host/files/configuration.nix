{ config, lib, pkgs, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
    settings.experimental-features = ["nix-command" "flakes"];
  };
  system.stateVersion = "23.05";
  nixpkgs.config.allowUnfree = true;
  imports = [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./config/role.nix
      ./config/nginx.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";
  #boot.loader.grub.useOSProber = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.useDHCP = false;
  networking.interfaces.enp2s0f0 = {
    useDHCP = true;
    wakeOnLan.enable = true;
  };
  networking.firewall.allowedTCPPorts = [
    22  # ssh
    8080  # nginx
    8443  # nginx
    8448  # synapse
  ];
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };
}

