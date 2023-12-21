{ name, ... }: {
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
    ./vault
    ./static-web-server
    ./monitoring
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "-";
      value = "8192";
    }
  ];
}
