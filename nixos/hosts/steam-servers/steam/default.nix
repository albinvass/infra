{ inputs, ... }:
{
  imports = [
    ./valheim.nix
    ./palworld.nix
    ./discord-server-status.nix
  ];
  nixpkgs.overlays = [ inputs.steam-fetcher.overlays.default ];
}
