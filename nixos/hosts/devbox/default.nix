{ ... }: {
  imports = [
    ../../modules/base
    ../../modules/disk-config
    ../../modules/development-tools
    ./minio
    ./cloudflared
    ./concourse
    ./keycloak
    ./davfs2
    ./postgresql
    ./matrix-synapse
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
