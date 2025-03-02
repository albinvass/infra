{ modulesPath, pkgs, ... }:
{
  system.stateVersion = "23.11";
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot = {
    loader.grub = {
      # no need to set devices, disko will add all devices that have a EF02 partition to the list already
      # devices = [ ];
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    kernelParams = [ "console=tty" ];
    initrd.kernelModules = [ "virtio_gpu" ];
  };
  services.openssh.enable = true;

  environment.systemPackages = [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.lvm2
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.firewall = {
    enable = true;
  };

  users.users.avass = {
    isNormalUser = true;
    home = "/home/avass";
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
  users.users.root.openssh.authorizedKeys.keys = [
    # Sops key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1UqvpGBn3Uk/DNIjFKSzLuItKcisQP+jtzaoSELliH vass@albin-xps159520"
    # Yubikey Green
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIDxPbSId6SM81tiIv8pLpZwOkJYVmF8EOlv9EHUJ9J5hAAAABHNzaDo= ssh:"
    # Yubikey Red
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBfzUf2VmDLW429RDVmzBmzrQ0Yv3XBJ+ytvv3Hm7QObAAAABHNzaDo= ssh:"
  ];

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
}
