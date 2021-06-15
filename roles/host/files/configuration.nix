# Edit this configuration file to define what should be installed on
{ config, pkgs, ... }:

{
  system.stateVersion = "21.05"; # Did you read the comment?
  nixpkgs.config.allowUnfree = true;
  imports = [
      ./hardware-configuration.nix # Include the results of the hardware scan.
      ./config/role.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp2s0f0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;
}

