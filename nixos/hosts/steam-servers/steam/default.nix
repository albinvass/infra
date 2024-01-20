{ steam-fetcher, ... }: {
  imports = [
    ./valheim.nix
    ./palworld.nix
 ];
  nixpkgs.overlays = [ steam-fetcher.overlays.default ];
}
