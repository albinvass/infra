{ config, ... }: 
{
  services.cloudflared.tunnels.devbox.ingress = let 
    keycloak-hostname = config.services.keycloak.settings.hostname;
    keycloak-http-port = builtins.toString config.services.keycloak.settings.http-port;
  in {
    "${keycloak-hostname}" = "http://localhost:${keycloak-http-port}";
  };

  services.postgresql = let
    keycloakDB = config.services.keycloak.database;
  in {
    ensureDatabases = [ keycloakDB.name ];
    ensureUsers = [{
      name = keycloakDB.username;
      ensurePermissions = {
        "DATABASE keycloak" = "ALL PRIVILEGES";
      };
    }];
  };

  sops.secrets = {
    "keycloak/db_password" = {
      owner = "keycloak";
      group = "keycloak";
      mode = "0600";
      restartUnits = [ "keycloak.service" ];
    };
  };

  users.users.keycloak = {
    group = "keycloak";
    isSystemUser = true;
  };
  users.groups.keycloak = {};
  services.keycloak = {
    enable = true;
    database = {
      createLocally = false;
      passwordFile = config.sops.secrets."keycloak/db_password".path;
    };
    settings = {
      hostname = "keycloak.albinvass.se";
      http-port = 10020;
      proxy = "edge";
    };
  };
}
