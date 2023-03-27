{config, pkgs, lib, ...}:
{
  imports = [
    ./davfs2.nix
    ./minio.nix
  ];
}
