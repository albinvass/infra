{ config, pkgs, ... }:
{
  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ./secrets.yaml;
  };

  nixpkgs.config.allowUnfree = true;

  imports = [
    "${fetchTarball {
      url = "https://github.com/NixOS/nixos-hardware/tarball/master";
      sha256 = "sha256:0jwif5q6cx6w391n6q6cpda79xxkp2ki40rpz71jpwhfq4b9wqfw";
    }}/raspberry-pi/4"
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
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

  sops.secrets = {
    "network/wireless.env" = {
      owner = "root";
      group = "root";
      mode = "0600";
      restartUnits = [ "wpa_supplicant-wlan0.service" ];
    };
  };

  networking = {
    wireless = {
      enable = true;
      networks."Bertil & Putte 5Ghz".psk = "@PSK_HOME@";
      interfaces = [ "wlan0" ];
      environmentFile = config.sops.secrets."network/wireless.env".path;
    };
  };

  environment.systemPackages = with pkgs; [ vim ];

  services.openssh.enable = true;

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
  security.sudo.extraRules = [{
    users = [ "avass" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
