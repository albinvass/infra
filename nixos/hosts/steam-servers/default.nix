{ inputs, ... }: {
  imports = [
    ./disks
    ./steam
    ../../modules/base
    inputs.sops-nix.nixosModules.sops
  ];

  nixpkgs.config.allowUnfree = true;

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };
}
