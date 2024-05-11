{ pkgs, ... }:
{
  imports = [
    ../../modules/base
    ./disk-config
    ./crowdsec.nix
    ./nginx.nix
    ./frp.nix
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  environment.systemPackages = [
    pkgs.git
    pkgs.podman
  ];

  security.pam.loginLimits = [
    {
      domain = "*";
      item = "nofile";
      type = "-";
      value = "8192";
    }
  ];
}
