{ config, lib, pkgs, modulesPath, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avass = {
    openssh = {
      authorizedKeys = {
        keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiMrbqfJf8c8MSne60fdxGTJQA1zLn67FRYxRZf6LeOjlUgQwZdrz8LA5f88BSzwm9uRh0mJTPwMKx0qe1fhuu9dy4GRGcL1Y2Rgg3IQqIScb0TyieLB+1J4EO5T+cFyPsh353p+7ZWq+/S0T5WtUB3VImGURwxzO6TvVaGnWs8HJtOsTQqmASBmIAVeN/f1lOK0jRg8MZji8LWU/LJzoH/+257Vhi8YpFe8G7W59cDW//h2ZwLtVdRvR1nYk4ZGyWKs9rh2RDOEslpOD0V1NMQgqB2YVd2Q13iKjqtO+EJKtX74jSe+xrpawOceULv9/3BOt+0eBKtjTkUTqPPo8maiarxzGsg+iuDYPPjYuwjJ61i4fADVMX7agBBX3t7f44rv1zTmdLGCzg+K5NqAue3fzP7EOozTlYL46+NLwBEOEFf75WQDp4GcCArS8oYxMrhSd/1na6HTYjtgiVyt+2xMR7jZns+9A+zuK614A4lH4eZKTc+nVUIHQ4mWkVi3s= avass@albin-xps159500"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjRbUx1aUZALLoWZ5L0F01QVtoPsnj7gYs9WWBBsJMbNvRZyXuYxJBCgG8YpY1W8aKaRLIsQSMMvfg62/W5ZjjnssONCUy9O56eFrxs7kNzMaobpd19WPuupfo0793c91ZM+3BnlIkZRuPZT3fCb1FFTybMJ6VThH1J3y6m2bGTcDMOWTMIxjGtc0RT61SF4luAQ81azwzyvhkP0QJnriDspy622RVcOh30lzUPYFylQwWm9lXIyBtJEwyUqc/rE4P6u230SZFkMF6GjREKIYATvdowiWMbQsONKO7emg0Wxa7ylEpduDBHIaI4ylZGc/UY8cl763rMOJ01Kjr/Zm9hjy3KskWLuOd8isYK9Pk0bmymbQ2O/edlneXPesr46x4Hm9ewD62gfINEiYHjlfEstabc1VGXEgwSKIB6YO11uFkpnICMb5RNInUZHUx1HNiTCq4+Vc5WQMKg0qGRTQmgQooO+Omu6P5MeuJHOFQdsELeTUBb+01xprsnY8vcXc= vass@albin-xps159520"
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDURjKPzXx+FoeftBq3gkBN9MKjW9g/oLVPhq9tR4o67o0TMU2UNdQSJtn3zwkGVpJ7US6lEcXViyzheF0UtTH8z5xNxLGKHMDJ2OGIkbI803Op+uFxvNRVhJ6oAAJE9COrQY4SLKxDbnt5P1s+pRnof3MWNmIbIeRhAPhvtg4PeMUnAvZFLbApSKuQIGYntHkzUPGqm6o7ecju0/Vs/a65q5ehxENX2f2eMmCEWPS/sVmIvhwH8npghAmMS76du5mj8pjVdyH5/fq6ys9naH50Hb7LGw1lX8ob7vQ/AqJpQ6qDjy0QYZGn7YK+W9WmThhU63EPQaTmGyw1BCEXpZvbabnsA22a0GfHAQFrdlS0mNaGDMVwCsLWa77WirX60jekzOJyh1dysA2hSPCRF38pGQXyOG5uSp228Sw09dUvNwC3fBeoTrObqHpwzKiOiZ568vO/V3tZlnrG7ZcYFolINn37RGJ1+jWkyTa4sRv9upCTImq27169VSfxt/nd1E8= vagrant@localhost.localdomain"
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
}
