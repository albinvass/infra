{ ... }:
{
  imports = [
    ../../modules/base
    ../../modules/disk-config
    ../../modules/development-tools
    ./cloudflared
    ./matrix-synapse
    ./static-web-server
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
