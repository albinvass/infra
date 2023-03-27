{config, pkgs, lib, ...}:
{
  services.vault.enable = true;
  services.vault.address = "0.0.0.0:80";
  services.vault.storageBackend = "file";
  services.vault.storagePath = "/var/lib/vault/1";
  services.vault.package = pkgs.vault-bin;
  services.vault.extraConfig = ''
    ui = true
  '';

  networking.firewall.allowedTCPPorts = [ 80 ];
}

