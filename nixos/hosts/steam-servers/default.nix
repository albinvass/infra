{ inputs, ... }: {
  imports = [
    ../../modules/base
    ./disks
    ./steam
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
  ];
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };
}
