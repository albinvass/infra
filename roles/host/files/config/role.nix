{ config, lib, pkgs, modulesPath, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avass = {
    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDKbLYpCk1iBrWTv9a1ovXmnOAwihCXg2H1YVSU1toEj4ko4DJc5vn+4aqynIVKUJpyOZoWx1xrPdUN0x8jXYKaKwLFG8J8Ftdyo8feqrzqg3EbLz0GtnYYIL20B7OTISrlD0dLGikhnzI2QpQ71fQqlFS+Fu313Djll9jZ3UavQOGMRJR1b/H4+tTkkpIf8SNxLCj5FusymryYKIBuzRB4ktA7Clmi9do0BpzfwOLioBMNVS36DsQ2DnQ0V2L4QdrKMkDuiAeD6Ys6g6JwUVCz+H/+M12cQRRInAUkKScyYCADdBlWlkUpt8KkXFjQigOQwXSQ8wT/xLMX710WqV9lNbqbP/V8O11RU99fF9oPdTg35/ZzgJUx2vl/fkxfoTA/WQda8xW6Lpem8ShdOBeOuNFB72ur0fb92QZnRRf66eocEuHJ5JpnywwWseU5HdVT2u0ga8uhjSEdS4p25Xl/oKVtYEWq61dSz0R+cb08CoWYrMB/0JUd58Qssqyew/U= vass@albin-xps159520"
        ];
      };
    };
    isNormalUser = true;
    extraGroups = [ "qemu-libvirtd" "libvirtd" "wheel" "video" "audio" "disk" "networkmanager" ];
  };

  security.sudo.extraRules = [{
    users = [ "avass" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.sessionVariables = rec {
    VAGRANT_DEFAULT_PROVIDER="libvirt";
  };

  virtualisation.libvirtd.enable = true;
  boot.kernelModules = ["kvm-amd"];

  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    kubectl
    kubernetes-helm
    vagrant
    (python38.buildEnv.override {
      extraLibs = with python38Packages; [
        hvac
        pyyaml
      ];
    })
  ];

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  console.keyMap = "sv-latin1";
  time.timeZone = "Europe/Stockholm";

  services.k3s.enable = true;

  services.grafana = {
    enable = true;
    addr = "0.0.0.0";
  };

  services.prometheus = {
    enable = true;
    extraFlags = [
      "--storage.tsdb.retention.size 10GB"
    ];
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
          }
        ];
      }
    ];
    exporters = {
      node = {
        enable = false;
        enabledCollectors = [
          "conntrack"
          "cpu"
          "diskstats"
          "entropy"
          "filefd"
          "filesystem"
          "loadavg"
          "mdadm"
          "meminfo"
          "netdev"
          "netstat"
          "stat"
          "time"
          "vmstat"
          "systemd"
          "logind"
          "interrupts"
          "ksmd"
        ];
      };
    };
  };

  services.elasticsearch = {
    package = pkgs.elasticsearch7;
    enable = true;
  };

  services.kibana = {
    package = pkgs.kibana7;
    enable = true;
    extraConf = {
      server.basePath = "/kibana";
      server.rewriteBasePath = true;
    };
  };
}
