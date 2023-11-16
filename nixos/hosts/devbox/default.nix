{ modulesPath, config, lib, pkgs, options, ... }: {
  imports = [
    ../../modules/base
    ../../modules/development-tools
    ./minio
    ./cloudflared
    ./davfs2
    ./code-server
    ./keycloak
    ./postgresql
    ./matrix-synapse
  ];
}
