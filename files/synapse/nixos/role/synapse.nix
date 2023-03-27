{config, pkgs, lib, ...}:
{
  networking.firewall.allowedTCPPorts = [ 8008 ];
  services.matrix-synapse = {
    enable = true;
    dataDir = "/var/lib/matrix-synapse";
    settings = {
      server_name = "matrix.vassast.org";
      signing_key_path = "/etc/matrix-synapse/keys/vassast.org.signing.key";
      listeners = [
        {
          port = 8008;
          bind_addresses = ["0.0.0.0"];
          type = "http";
          tls = false;
          x_forwarded = true;
          resources = [{
            names = [ "client" "federation" ];
            compress = true;
          }];
        }
      ];
      database.name = "sqlite3";
    };
    extraConfigFiles = [
      "/etc/matrix-synapse/secrets"
    ];
  };
}
