{ config, pkgs, lib, ... }: 
rec {
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

  deployment = {
    keys = {
      "db_password" = {
        destDir = "/etc/keycloak";
        keyCommand = ["bws-get" "postgres-keycloak"];
        user = "keycloak";
        group = "keycloak";
        permissions = "0600";
      };
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
      passwordFile = "/etc/keycloak/db_password";
    };
    settings = {
      hostname = "keycloak.albinvass.se";
      http-port = 8080;
      proxy = "edge";
    };
  };
}
