{ config, lib, pkgs, modulesPath, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avass = {
    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiMrbqfJf8c8MSne60fdxGTJQA1zLn67FRYxRZf6LeOjlUgQwZdrz8LA5f88BSzwm9uRh0mJTPwMKx0qe1fhuu9dy4GRGcL1Y2Rgg3IQqIScb0TyieLB+1J4EO5T+cFyPsh353p+7ZWq+/S0T5WtUB3VImGURwxzO6TvVaGnWs8HJtOsTQqmASBmIAVeN/f1lOK0jRg8MZji8LWU/LJzoH/+257Vhi8YpFe8G7W59cDW//h2ZwLtVdRvR1nYk4ZGyWKs9rh2RDOEslpOD0V1NMQgqB2YVd2Q13iKjqtO+EJKtX74jSe+xrpawOceULv9/3BOt+0eBKtjTkUTqPPo8maiarxzGsg+iuDYPPjYuwjJ61i4fADVMX7agBBX3t7f44rv1zTmdLGCzg+K5NqAue3fzP7EOozTlYL46+NLwBEOEFf75WQDp4GcCArS8oYxMrhSd/1na6HTYjtgiVyt+2xMR7jZns+9A+zuK614A4lH4eZKTc+nVUIHQ4mWkVi3s= avass@albin-xps159500"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjRbUx1aUZALLoWZ5L0F01QVtoPsnj7gYs9WWBBsJMbNvRZyXuYxJBCgG8YpY1W8aKaRLIsQSMMvfg62/W5ZjjnssONCUy9O56eFrxs7kNzMaobpd19WPuupfo0793c91ZM+3BnlIkZRuPZT3fCb1FFTybMJ6VThH1J3y6m2bGTcDMOWTMIxjGtc0RT61SF4luAQ81azwzyvhkP0QJnriDspy622RVcOh30lzUPYFylQwWm9lXIyBtJEwyUqc/rE4P6u230SZFkMF6GjREKIYATvdowiWMbQsONKO7emg0Wxa7ylEpduDBHIaI4ylZGc/UY8cl763rMOJ01Kjr/Zm9hjy3KskWLuOd8isYK9Pk0bmymbQ2O/edlneXPesr46x4Hm9ewD62gfINEiYHjlfEstabc1VGXEgwSKIB6YO11uFkpnICMb5RNInUZHUx1HNiTCq4+Vc5WQMKg0qGRTQmgQooO+Omu6P5MeuJHOFQdsELeTUBb+01xprsnY8vcXc= vass@albin-xps159520"
        ];
      };
    };
    isNormalUser = true;
  };

  security.sudo.extraRules = [{
    users = [ "avass" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  environment.systemPackages = with pkgs; [
    neovim
    curl
    git
    kubectl
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

  #services.elasticsearch = {
  #  package = pkgs.elasticsearch7;
  #  enable = false;
  #};

  #services.kibana = {
  #  package = pkgs.kibana7;
  #  enable = false;
  #  extraConf = {
  #    server.basePath = "/kibana";
  #    server.rewriteBasePath = true;
  #  };
  #};

  console.keyMap = "sv-latin1";
  time.timeZone = "Europe/Stockholm";

  services.k3s.enable = true;
  services.grafana = {
    enable = true;
    addr = "0.0.0.0";
  };
  services.prometheus = {
    enable = false;
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
}
