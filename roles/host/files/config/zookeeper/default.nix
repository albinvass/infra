{ config, lib, pkgs, vinemetrics-irc, ... }:
let
  ca-cfg = {
    user = "root";
    path = "zookeeper/ca";
  };
  zookeeper-certs-cfg = {
    user = "999";  # zookeeper user in container
    path = "zookeeper/certs";
  };
in rec {
  systemd.services."create-zookeeper-ca" = {
    description = "Create CA for zookeeper";
    script = ''
      set -euo pipefail
      ${pkgs.libressl}/bin/openssl req \
        -x509 \
        -newkey rsa:4096 \
        -keyout cakey.pem \
        -out cacert.pem \
        -days 365 \
        -nodes \
        -subj '/CN=Zookeeper-CA'

      chmod 644 cacert.pem
      chmod 640 cakey.pem
    '';
    wantedBy = [
      "multi-user.target"
      "create-zookeeper-certs.service"
    ];
    unitConfig = {
      Before = [
        "multi-user.target"
        "create-zookeeper-certs.service"
      ];
      ConditionPathExists = "!${ca-cfg.path}/cacert.pem";
    };
    serviceConfig = {
      User = ca-cfg.user;
      Type = "oneshot";
      StateDirectory = ca-cfg.path;
      WorkingDirectory = "/var/lib/${ca-cfg.path}";
      RemainAfterExit = true;
    };
  };
  systemd.services."create-zookeeper-certs" = {
    description = "Create certs for zookeeper";
    script = ''
      set -euo pipefail
      ${pkgs.libressl}/bin/openssl req \
        -nodes \
        -newkey \
        rsa:4096 \
        -keyout zookeeper-1-key.pem \
        -out zookeeper-1.csr \
        -subj "/C=SE/CN=zookeeper-1" \

      ${pkgs.libressl}/bin/openssl x509 \
        -req \
        -in zookeeper-1.csr \
        -CA ${systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cacert.pem \
        -CAkey ${systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cakey.pem \
        -CAcreateserial \
        -days 365 \
        -sha256 \
        -out zookeeper-1-cert.pem

      cat zookeeper-1-cert.pem zookeeper-1-key.pem > zookeeper-1.pem

      cp ${systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cacert.pem cacert.pem
      chmod 644 zookeeper-1-cert.pem
      chmod 640 zookeeper-1-key.pem
      chmod 640 zookeeper-1.pem
      chown -R ${zookeeper-certs-cfg.user}:${zookeeper-certs-cfg.user} .
    '';
    wantedBy = [
      "multi-user.target"
      "container@zookeeper-1.service"
    ];
    unitConfig = {
      Before = [
        "multi-user.target"
        "container@zookeeper-1.service"
      ];
      ConditionPathExists = "!${zookeeper-certs-cfg.path}/zookeeper-1.pem";
    };
    serviceConfig = {
      User = ca-cfg.user;
      Type = "oneshot";
      StateDirectory = zookeeper-certs-cfg.path;
      WorkingDirectory = "/var/lib/${zookeeper-certs-cfg.path}";
      RemainAfterExit = true;
    };
  };
  containers.zookeeper-1 = {
    autoStart = true;
    config =
      { config, pkgs, ...}:
      {
        services.zookeeper = {
          enable = true;
          id = 0;
          dataDir = "/var/lib/zookeeper/data";
          extraConf = builtins.readFile ./zoo.cfg;
          extraCmdLineOptions = [
            "-Dzookeeper.datadir.autocreate=true"
          ];
          logging = builtins.readFile ./log.cfg;
        };
        networking.firewall.allowedTCPPorts = [ 2281 ];
      };
    bindMounts = {
      "/var/lib/zookeeper/certs" = {
        hostPath = "/var/lib/zookeeper/certs";
        isReadOnly = true;
      };
    };
    privateNetwork = true;
    hostAddress = "192.168.100.10";
    localAddress = "192.168.100.11";
  };
}
