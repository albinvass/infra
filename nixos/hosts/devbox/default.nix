{ modulesPath, config, lib, pkgs, options, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/development-tools
    ../../modules/base
    ./minio
    ./cloudflared
    ./davfs2
    ./code-server
    ./keycloak
    ./postgresql
  ];
}
