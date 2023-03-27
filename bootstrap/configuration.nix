{ config, lib, pkgs, ... }:

{
  system.stateVersion = "23.05";
  imports = [
    ./site.nix
  ];
}
