{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./cloudflared.nix
    ./frp.nix
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    podman
  ];

  services = {
    openssh.enable = true;
    postgresql = {
      ensureDatabases = [ "splitfree" ];
      ensureUsers = [
        {
          name = "splitfree";
          ensureDBOwnership = true;
          ensureClauses = {
            login = true;
          };
        }
      ];
    };
  };

  users = {
    mutableUsers = false;
    users.avass = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1UqvpGBn3Uk/DNIjFKSzLuItKcisQP+jtzaoSELliH vass@albin-xps159520"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiIF1+kZ33rssTtjwtiSVtug6akSMH7zXFI3AEqbTf6 avass@dellxps"
      ];
    };
  };
  time.timeZone = "Europe/Stockholm";
  console.keyMap = "sv-latin1";

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
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
  virtualisation.containers.enable = true;
}
