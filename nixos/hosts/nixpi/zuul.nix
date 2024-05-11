{ config, pkgs, lib, ... }:
let
  zuulWebPort = "9000";
in
{
  services.cloudflared = {
    tunnels = {
      nixpi = {
        ingress = {
          "zuul.albinvass.se" = "http://localhost:${zuulWebPort}";
        };
      };
    };
  };
  users = {
    users.zuul = {
      group = "zuul";
      isSystemUser = true;
    };
    groups.zuul = {};
  };
  sops.secrets = {
    "zuul/cifs" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
    "zuul/env" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };

  fileSystems."/var/lib/zuul" = {
    device = "//storage/zuul";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in ["${automount_opts},credentials=${config.sops.secrets."zuul/cifs".path}"];
  };

  virtualisation.oci-containers.containers = let
    volumeBasePath = "/var/lib/zuul";
    zuulConf = pkgs.writeText "zuul.conf" (lib.generators.toINI {} {
      zookeeper = {
        hosts="zookeeper-0:2281";
        tls_cert="/etc/zuul/zookeeper/client.pem";
        tls_key="/etc/zuul/zookeeper/clientkey.pem";
        tls_ca="/etc/zuul/zookeeper/cacert.pem";
      };
      keystore = {
        password="%(ZUUL_KEYSTORE_PASSWORD)s";
      };
      scheduler = {
        tenant_config="/etc/zuul/main.yaml";
      };
      database = {
        dburi="%(ZUUL_DATABASE_URI)s";
      };
      web = {
        listen_address="127.0.0.1";
        port="9000";
        root="https://zuul.albinvass.se";
      };
      executor = {
        private_key_file="/etc/zuul/nodepool";

      };
    });
  in {
    "zuul-scheduler-0" = {
      hostname = "zuul-scheduler-0";
      image = "quay.io/zuul-ci/zuul-scheduler:nixpi";
      environmentFiles = [
        config.sops.secrets."zuul/env".path
      ];
      volumes = [
        "${volumeBasePath}/zuul-scheduler-0"
        "${zuulConf}:/etc/zuul/zuul.conf"
      ];
    };
    "zuul-executor-0" = {
      hostname = "zuul-executor-0";
      image = "quay.io/zuul-ci/zuul-executor:nixpi";
      environmentFiles = [
        config.sops.secrets."zuul/env".path
      ];
      volumes = [
        "${volumeBasePath}/zuul-executor-0"
        "${zuulConf}:/etc/zuul/zuul.conf"
      ];
    };
    "zuul-web-0" = {
      hostname = "zuul-web-0";
      image = "quay.io/zuul-ci/zuul-web:nixpi";
      environmentFiles = [
        config.sops.secrets."zuul/env".path
      ];
      volumes = [
        "${zuulConf}:/etc/zuul/zuul.conf"
      ];
    };
    "zookeeper-0" = {
      hostname = "zookeeper-0";
      image = "docker.io/zookeeper";
      volumes = [
        "${volumeBasePath}/zookeeper-0"
      ];
    };
  };
}

