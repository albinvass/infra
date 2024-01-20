{ inputs, ... }: {
  imports = [
    ./valheim.nix
    ./palworld.nix
 ];
  nixpkgs.overlays = [ inputs.steam-fetcher.overlays.default ];
}
