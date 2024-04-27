{ config, ...}:
let
  concourseWebPort = "8080";
in {
  services = {
    cloudflared.tunnels.devbox.ingress = {
      "concourse.albinvass.se" = "http://localhost:${concourseWebPort}";
    };
    postgresql = {
      ensureDatabases = [ "concourse" ];
      ensureUsers = [{
        name = "concourse";
        ensureDBOwnership = true;
        ensureClauses = {
          login = true;
        };
      }];
    };
  };

  users.groups.concourse = {};
  users.users.concourse = {
    isSystemUser = true;
    home = "/var/lib/concourse";
    createHome = true;
    homeMode = "750";
    group = "concourse";
  };

  sops.secrets = {
    "concourse/encryption-keys/session-signing-key" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/encryption-keys/tsa-host-key" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/encryption-keys/tsa-authorized-keys" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/common/environment" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/web/environment" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/worker/environment" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
  };

  virtualisation.oci-containers.containers = {
    concourse-web = {
      image = "concourse/concourse";
      cmd = ["web"];
      extraOptions = [ "--network=host" ];
      ports = [
        "${concourseWebPort}:8080"
      ];
      volumes = [
        "${config.sops.secrets."concourse/encryption-keys/session-signing-key".path}:/etc/concourse/session-signing-key"
        "${config.sops.secrets."concourse/encryption-keys/tsa-host-key".path}:/etc/concourse/tsa-host-key"
        "${config.sops.secrets."concourse/encryption-keys/tsa-authorized-keys".path}:/etc/concourse/tsa-authorized-keys"
      ];
      environment = {
        CONCOURSE_SESSION_SIGNING_KEY="/etc/concourse/session-signing-key";
        CONCOURSE_TSA_HOST_KEY="/etc/concourse/tsa-host-key";
        CONCOURSE_TSA_AUTHORIZED_KEYS="/etc/concourse/tsa-authorized-keys";
        CONCOURSE_EXTERNAL_URL="https://concourse.albinvass.se";
        CONCOURSE_DEFAULT_BUILD_LOGS_TO_RETAIN="50";
        CONCOURSE_DEFAULT_DAYS_TO_RETAIN_BUILD_LOGS="14";
      };
      environmentFiles = [
        config.sops.secrets."concourse/common/environment".path
        config.sops.secrets."concourse/web/environment".path
      ];
    };
    concourse-worker = {
      image = "concourse/concourse";
      cmd = ["worker"];
      extraOptions = [ "--network=host" ];
      environmentFiles = [
        config.sops.secrets."concourse/common/environment".path
        config.sops.secrets."concourse/worker/environment".path
      ];
    };
  };
}
