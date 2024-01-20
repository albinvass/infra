{ modulesPath, pkgs, ... }: {
  system.stateVersion = "23.11";
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.kernelParams = [ "console=tty" ];
  boot.initrd.kernelModules = [ "virtio_gpu" ];
  services.openssh.enable = true;

  environment.systemPackages = [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.lvm2
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.firewall = {
    enable = true;
  };

  users.users.avass = {
    isNormalUser = true;
    home = "/home/avass";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKbLYpCk1iBrWTv9a1ovXmnOAwihCXg2H1YVSU1toEj4ko4DJc5vn+4aqynIVKUJpyOZoWx1xrPdUN0x8jXYKaKwLFG8J8Ftdyo8feqrzqg3EbLz0GtnYYIL20B7OTISrlD0dLGikhnzI2QpQ71fQqlFS+Fu313Djll9jZ3UavQOGMRJR1b/H4+tTkkpIf8SNxLCj5FusymryYKIBuzRB4ktA7Clmi9do0BpzfwOLioBMNVS36DsQ2DnQ0V2L4QdrKMkDuiAeD6Ys6g6JwUVCz+H/+M12cQRRInAUkKScyYCADdBlWlkUpt8KkXFjQigOQwXSQ8wT/xLMX710WqV9lNbqbP/V8O11RU99fF9oPdTg35/ZzgJUx2vl/fkxfoTA/WQda8xW6Lpem8ShdOBeOuNFB72ur0fb92QZnRRf66eocEuHJ5JpnywwWseU5HdVT2u0ga8uhjSEdS4p25Xl/oKVtYEWq61dSz0R+cb08CoWYrMB/0JUd58Qssqyew/U= vass@albin-xps159520"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1UqvpGBn3Uk/DNIjFKSzLuItKcisQP+jtzaoSELliH vass@albin-xps159520"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKbLYpCk1iBrWTv9a1ovXmnOAwihCXg2H1YVSU1toEj4ko4DJc5vn+4aqynIVKUJpyOZoWx1xrPdUN0x8jXYKaKwLFG8J8Ftdyo8feqrzqg3EbLz0GtnYYIL20B7OTISrlD0dLGikhnzI2QpQ71fQqlFS+Fu313Djll9jZ3UavQOGMRJR1b/H4+tTkkpIf8SNxLCj5FusymryYKIBuzRB4ktA7Clmi9do0BpzfwOLioBMNVS36DsQ2DnQ0V2L4QdrKMkDuiAeD6Ys6g6JwUVCz+H/+M12cQRRInAUkKScyYCADdBlWlkUpt8KkXFjQigOQwXSQ8wT/xLMX710WqV9lNbqbP/V8O11RU99fF9oPdTg35/ZzgJUx2vl/fkxfoTA/WQda8xW6Lpem8ShdOBeOuNFB72ur0fb92QZnRRf66eocEuHJ5JpnywwWseU5HdVT2u0ga8uhjSEdS4p25Xl/oKVtYEWq61dSz0R+cb08CoWYrMB/0JUd58Qssqyew/U= vass@albin-xps159520
" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1UqvpGBn3Uk/DNIjFKSzLuItKcisQP+jtzaoSELliH vass@albin-xps159520"
  ];

  security.sudo.extraRules = [{
    users = [ "avass" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
