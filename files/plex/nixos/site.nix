{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  networking.useDHCP = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  services.qemuGuest.enable = true;
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  users.users.avass = {
    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKbLYpCk1iBrWTv9a1ovXmnOAwihCXg2H1YVSU1toEj4ko4DJc5vn+4aqynIVKUJpyOZoWx1xrPdUN0x8jXYKaKwLFG8J8Ftdyo8feqrzqg3EbLz0GtnYYIL20B7OTISrlD0dLGikhnzI2QpQ71fQqlFS+Fu313Djll9jZ3UavQOGMRJR1b/H4+tTkkpIf8SNxLCj5FusymryYKIBuzRB4ktA7Clmi9do0BpzfwOLioBMNVS36DsQ2DnQ0V2L4QdrKMkDuiAeD6Ys6g6JwUVCz+H/+M12cQRRInAUkKScyYCADdBlWlkUpt8KkXFjQigOQwXSQ8wT/xLMX710WqV9lNbqbP/V8O11RU99fF9oPdTg35/ZzgJUx2vl/fkxfoTA/WQda8xW6Lpem8ShdOBeOuNFB72ur0fb92QZnRRf66eocEuHJ5JpnywwWseU5HdVT2u0ga8uhjSEdS4p25Xl/oKVtYEWq61dSz0R+cb08CoWYrMB/0JUd58Qssqyew/U= vass@albin-xps159520"
        ];
      };
    };
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" ];
  };

  security.sudo.extraRules = [{
    users = [ "avass" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.systemPackages = with pkgs; [
    parted
    vim
    (python38.buildEnv.override {
      extraLibs = with python38Packages; [
        hvac
        pyyaml
      ];
    })
  ];
}