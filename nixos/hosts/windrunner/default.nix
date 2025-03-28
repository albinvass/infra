{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./frp.nix
    ./immich.nix
    ./hardware-configuration.nix
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  services = {
    openssh.enable = true;
  };

  users = {
    mutableUsers = false;
    users.avass = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
      # Sops key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1UqvpGBn3Uk/DNIjFKSzLuItKcisQP+jtzaoSELliH vass@albin-xps159520"
      # Yubikey Green
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDxPbSId6SM81tiIv8pLpZwOkJYVmF8EOlv9EHUJ9J5hAAAABHNzaDo= ssh:"
      # Yubikey Red
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBfzUf2VmDLW429RDVmzBmzrQ0Yv3XBJ+ytvv3Hm7QObAAAABHNzaDo= ssh:"
      ];
    };
  };
  time.timeZone = "Europe/Stockholm";
  console.keyMap = "sv-latin1";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "24.11";
  security.sudo.extraRules = [
    {
      users = [ "avass" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  networking.firewall = {
    enable = true;
  };
}

