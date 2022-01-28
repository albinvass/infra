{ config, lib, pkgs, vinemetrics-irc, ... }:

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
      ./config/zuul
      ./config/zookeeper
  ];

  age.secrets.vinescore-oauth-token.file = ./secrets/vinescore-oauth-token.age;
  virtualisation.oci-containers.containers = {
    vinemetrics-irc = {
      image = "vinemetrics-irc:${lib.head (lib.strings.splitString "-" (baseNameOf vinemetrics-irc.packages.x86_64-linux.container))}";
      imageFile = vinemetrics-irc.packages.x86_64-linux.container;
      environmentFiles = [ config.age.secrets.vinescore-oauth-token.path ];
      environment = {
        VINESCORE_CHANNELS = "#vassast";
      };
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp2s0f0.useDHCP = true;
  networking.interfaces.wlp3s0.useDHCP = true;
  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
  networking.nat.externalInterface = "bridge0";
  networking.firewall.allowedTCPPorts = [ 22 6443 30000 32400 80 8080 8443 8448 ];
  networking.interfaces.bridge0.useDHCP = true;
  networking.bridges = {
    "bridge0" = {
      interfaces = [ "enp2s0f0" ];
    };
  };

}

