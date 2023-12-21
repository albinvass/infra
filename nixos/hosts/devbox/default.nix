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

  deployment = {
    keys = {
      "ssh_host_ed25519_key" = {
        destDir = "/etc/ssh";
        keyCommand = ["get-host-key" name "ssh_host_ed25519_key"];
        user = "root";
        group = "root";
        permissions = "0600";
      };
      "ssh_host_ed25519_key.pub" = {
        destDir = "/etc/ssh";
        keyCommand = ["get-host-key" name "ssh_host_ed25519_key.pub"];
        user = "root";
        group = "root";
        permissions = "0644";
      };
    };
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
