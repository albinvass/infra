{config, pkgs, lib, ...}:
{
  services.cloudflared.tunnels.devbox.ingress = {
    "vault.albinvass.se" = "http://localhost:8070";
  };

  fileSystems."/var/lib/vault" = {
    device = "/dev/data/vault";
    fsType = "ext4";
  };

  services.vault = {
    enable = true;
    # Needed for vault UI
    package = pkgs.vault-bin;
    address = "0.0.0.0:8070";
    storageBackend = "file";
    storagePath = "/var/lib/vault/data";
    extraConfig = ''
      ui = true
    '';
  };
}
