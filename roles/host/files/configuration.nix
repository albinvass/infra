{ config, lib, pkgs, ... }:

{
  nix = {
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  system.stateVersion = "21.05";
  nixpkgs.config.allowUnfree = true;
  imports = [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./config/role.nix
      ./config/nginx.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_15;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    9090  # prometheus
  ];
  powerManagement.enable = false;
}

