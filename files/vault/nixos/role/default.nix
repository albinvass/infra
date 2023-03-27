{config, pkgs, lib, ...}:
{
  imports = [
    ./davfs2.nix
    ./vault.nix
  ];
}
