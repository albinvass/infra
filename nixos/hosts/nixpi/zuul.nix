{ config, pkgs, lib, ... }:
{
  virtualisation.podman.defaultNetwork.settings = { dns_enabled = true; };

  users = {
    users = {
      zuul = {
        uid = 10001;
        group = "zuul";
        isSystemUser = true;
      };
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
    "zuul/certs/client.pem" = {
      owner = "zuul";
    };
    "zuul/certs/clientkey.pem" = {
      owner = "zuul";
    };
    "zuul/certs/cacert.pem" = {
      owner = "zuul";
    };
    "zuul/connections/github/private-key" = {
      owner = "zuul";
    };
    "zuul/nodepool/ssh_id_ed25519" = {
      owner = "zuul";
    };
    "zookeeper/certs/client.pem" = {
      owner = "zuul";
    };
    "zookeeper/certs/cacert.pem" = {
      owner = "zuul";
    };
  };

  fileSystems."/var/lib/zuul" = {
    device = "//storage/home";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,uid=${builtins.toString config.users.users.zuul.uid}";
    in ["${automount_opts},credentials=${config.sops.secrets."zuul/cifs".path}"];
  };

  virtualisation.oci-containers.containers = let
    volumeBasePath = "/var/lib/zuul";
    zuulTenantConf = pkgs.writeText "main.yaml" (lib.generators.toYAML {} [{
      tenant = {
        name = "albinvass";
        source = {
          github = {
            config-projects = [
              { "albinvass/zuul-config" = {}; }
            ];
            untrusted-projects = [
              { "albinvass/infra" = {}; }
            ];
          };
          "opendev.org" = {
            untrusted-projects = [
              { "zuul/zuul-jobs" = {}; }
            ];
          };
        };
      };
    }]);
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
      "connection \"github\"" = {
        driver="github";
        webhook_token = "%(ZUUL_GITHUB_WEBHOOK_TOKEN)s";
        app_id = "920959";
        app_key = "/etc/zuul/github.pem";
        api_token = "%(ZUUL_GITHUB_API_TOKEN)s";
      };
      "connection \"opendev.org\"" = {
        driver = "git";
        baseurl = "https://opendev.org";
      };
      web = {
        listen_address="0.0.0.0";
        port="9000";
        root="https://zuul.albinvass.se";
      };
      executor = {
        private_key_file="/etc/zuul/nodepool";
      };
    });
    zookeeperConf = pkgs.writeText "zoo.cfg" ''
      # Necessary for TLS support
      serverCnxnFactory=org.apache.zookeeper.server.NettyServerCnxnFactory

      dataDir=/data

      # Client TLS configuration
      secureClientPort=2281
      ssl.keyStore.location=/etc/zookeeper/client.pem
      ssl.trustStore.location=/etc/zookeeper/cacert.pem

      # Server TLS configuration
      sslQuorum=true
      ssl.quorum.keyStore.location=/etc/zookeeper/client.pem
      ssl.quorum.trustStore.location=/etc/zookeeper/cacert.pem
    '';
    zuulExecutorCount = 1;
    zuulSchedulerCount = 1;
    zuulWebCount = 1;
    zuulSystem = let
      sharedVolumes = [
        "${zuulConf}:/etc/zuul/zuul.conf"
        "${config.sops.secrets."zuul/certs/client.pem".path}:/etc/zuul/zookeeper/client.pem"
        "${config.sops.secrets."zuul/certs/clientkey.pem".path}:/etc/zuul/zookeeper/clientkey.pem"
        "${config.sops.secrets."zuul/certs/cacert.pem".path}:/etc/zuul/zookeeper/cacert.pem"
        "${config.sops.secrets."zuul/connections/github/private-key".path}:/etc/zuul/github.pem"
      ];
      mkZuulComponent = {
        component,
        index,
        extraVolumes ? [],
        ports ? [],
        privileged ? false,
        imageRef ? "ghcr.io/albinvass/infra/zuul-${component}",
        imageTag ? "nixpi",
      }: let
          name = "zuul-${component}-${builtins.toString index}";
        in {
          inherit name;
          value = {
            inherit ports;
            hostname = "${name}.${config.networking.hostName}.albinvass.se";
            image = "${imageRef}:${imageTag}";
            user = if privileged then "root" else builtins.toString config.users.users.zuul.uid;
            cmd =
              let
                certDownload = "curl --create-dirs -o $HOME/.postgresql/root.crt 'https://cockroachlabs.cloud/clusters/109cbe58-6e1a-4f67-a7be-b8b6261815fd/cert'";
                cockroachDBInstall = "pip install sqlalchemy-cockroachdb";
              in ["bash" "-c" "${cockroachDBInstall} && ${certDownload} && zuul-${component} -d -f"];
            environmentFiles = [
              config.sops.secrets."zuul/env".path
            ];
            volumes = sharedVolumes ++ extraVolumes;
            extraOptions = if privileged then ["--privileged"] else [];
          };
        };
      mkZuulScheduler = index: let
          component = "scheduler";
          extraVolumes = [
            "${zuulTenantConf}:/etc/zuul/main.yaml"
          ];
        in mkZuulComponent {inherit component index extraVolumes; };
      mkZuulExecutor = index: let
          component = "executor";
          extraVolumes = [
            "${volumeBasePath}/zuul-executor-${builtins.toString index}:/var/lib/zuul/builds"
            "${config.sops.secrets."zuul/nodepool/ssh_id_ed25519".path}:/etc/zuul/nodepool"
          ];
        in mkZuulComponent {
          inherit component index extraVolumes;
          privileged = true;
          imageTag = "latest";
        };
      mkZuulWeb = index: let
          component = "web";
          extraVolumes = [
            "${zuulTenantConf}:/etc/zuul/main.yaml"
          ];
          ports = [
            "9000:9000"
          ];
        in mkZuulComponent {inherit component index extraVolumes ports; };

      mkZuulSystem = { schedulers ? 0, executors ? 0, webs ? 0 }: let
          zuulSchedulers = builtins.listToAttrs (builtins.map
            mkZuulScheduler
            (lib.lists.range 1 schedulers));
          zuulExecutors = builtins.listToAttrs (builtins.map
            mkZuulExecutor
            (lib.lists.range 1 schedulers));
          zuulWebs = builtins.listToAttrs (builtins.map
            mkZuulWeb
            (lib.lists.range 1 schedulers));
        in zuulSchedulers // zuulExecutors // zuulWebs;
     in mkZuulSystem {
          schedulers = zuulSchedulerCount;
          executors = zuulExecutorCount;
          webs = zuulWebCount;
        };
  in zuulSystem // {
    "zookeeper-0" = {
      hostname = "zookeeper-0";
      #cmd = [ "sleep" "infinity" ];
      user = builtins.toString config.users.users.zuul.uid;
      image = "docker.io/zookeeper";
      volumes = [
        "${zookeeperConf}:/conf/zoo.cfg"
        "${volumeBasePath}/zookeeper-0/data:/data"
        "${volumeBasePath}/zookeeper-0/datalog:/datalog"
        "${config.sops.secrets."zookeeper/certs/client.pem".path}:/etc/zookeeper/client.pem"
        "${config.sops.secrets."zookeeper/certs/cacert.pem".path}:/etc/zookeeper/cacert.pem"
      ];
    };
  };
}

