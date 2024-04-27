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

  systemd.tmpfiles.rules = [
    "d /var/lib/concourse/worker-state 0755 concourse concourse"
  ];
  users.groups.concourse = {};
  users.users.concourse = {
    isSystemUser = true;
    home = "/var/lib/concourse";
    createHome = true;
    homeMode = "750";
    group = "concourse";
  };

  sops.secrets = {
    "concourse/session-signing-key" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/web/ssh_host_rsa_key" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/web/ssh_host_rsa_key.pub" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/worker/id_rsa" = {
      owner = "concourse";
      group = "concourse";
      mode = "0600";
    };
    "concourse/worker/id_rsa.pub" = {
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
        "${config.sops.secrets."concourse/session-signing-key".path}:/etc/concourse/session-signing-key"
        "${config.sops.secrets."concourse/web/ssh_host_rsa_key".path}:/etc/concourse/ssh_host_rsa_key"
        "${config.sops.secrets."concourse/worker/id_rsa.pub".path}:/etc/concourse/authorized-keys"
      ];
      environment = {
        CONCOURSE_SESSION_SIGNING_KEY="/etc/concourse/session-signing-key";
        CONCOURSE_TSA_HOST_KEY="/etc/concourse/ssh_host_rsa_key";
        CONCOURSE_TSA_AUTHORIZED_KEYS="/etc/concourse/authorized-keys";
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
      user = "root";
      dependsOn = ["concourse-web"];
      extraOptions = [ "--privileged" "--network=host" ];
      volumes = [
        "${config.sops.secrets."concourse/worker/id_rsa".path}:/etc/concourse/id_rsa"
        "${config.sops.secrets."concourse/web/ssh_host_rsa_key.pub".path}:/etc/concourse/tsa_host_key.pub"
        "/var/lib/concourse/worker-state:/worker-state"
      ];
      environment = {
        CONCOURSE_RUNTIME="containerd";
        CONCOURSE_WORK_DIR="/worker-state";
        CONCOURSE_TSA_HOST="localhost:2222";
        CONCOURSE_TSA_PUBLIC_KEY="/etc/concourse/tsa_host_key.pub";
        CONCOURSE_TSA_WORKER_PRIVATE_KEY="/etc/concourse/id_rsa";
      };
      environmentFiles = [
        config.sops.secrets."concourse/worker/environment".path
      ];
    };
  };
}
