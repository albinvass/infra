{config, pkgs, lib, ...}:
{
  imports = [
    ./plex.nix
    ./transmission.nix
    ./mullvad.nix
    ./tailscale.nix
  ];
}

