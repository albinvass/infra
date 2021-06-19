{ config, lib, pkgs, modulesPath, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.avass = {
    openssh = {
      authorizedKeys = {
        keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDiMrbqfJf8c8MSne60fdxGTJQA1zLn67FRYxRZf6LeOjlUgQwZdrz8LA5f88BSzwm9uRh0mJTPwMKx0qe1fhuu9dy4GRGcL1Y2Rgg3IQqIScb0TyieLB+1J4EO5T+cFyPsh353p+7ZWq+/S0T5WtUB3VImGURwxzO6TvVaGnWs8HJtOsTQqmASBmIAVeN/f1lOK0jRg8MZji8LWU/LJzoH/+257Vhi8YpFe8G7W59cDW//h2ZwLtVdRvR1nYk4ZGyWKs9rh2RDOEslpOD0V1NMQgqB2YVd2Q13iKjqtO+EJKtX74jSe+xrpawOceULv9/3BOt+0eBKtjTkUTqPPo8maiarxzGsg+iuDYPPjYuwjJ61i4fADVMX7agBBX3t7f44rv1zTmdLGCzg+K5NqAue3fzP7EOozTlYL46+NLwBEOEFf75WQDp4GcCArS8oYxMrhSd/1na6HTYjtgiVyt+2xMR7jZns+9A+zuK614A4lH4eZKTc+nVUIHQ4mWkVi3s= avass@albin-xps159500" ];
      };
    };
    isNormalUser = true;
    extraGroups = [
      "libvirtd"
    ];
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
    vagrant
    python3
  ];

  virtualisation.libvirtd.enable = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
  };

  console.keyMap = "sv-latin1";
  time.timeZone = "Europe/Stockholm";

  networking.firewall.allowedTCPPorts = [ 22 6443 30000 ];
  networking.interfaces.bridge0.useDHCP = true;
  networking.bridges = {
    "bridge0" = {
      interfaces = [ "enp2s0f0" ];
    };
  };
}
