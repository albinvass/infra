{ config, lib, pkgs, vinemetrics-irc, ... }:
let
  zuul-config = builtins.toFile "zuul.conf" "
  [zookeeper]
  hosts=zookeeper-1:2281
  tls_cert=/etc/zuul/certs/zuul-cert.pem
  tls_key=/etc/zuul/certs/zuul-key.pem
  tls_ca=/etc/zuul/certs/cacert.pem

  [database]
  dburi=mysql+pymysql://zuul:MY_SECRET_PASSWORD@mysql/zuul

  [keystore]
  password=MY_SECRET_PASSWORD

  [web]
  status_url=https://nixos:9001/status
  ";
  zuul-certs-cfg = {
    user = "10001";  # zuul user in container
    path = "zuul/certs";
  };
  zuul-volumes = [
    "${zuul-config}:/etc/zuul/zuul.conf"
    "/var/lib/${zuul-certs-cfg.path}:/etc/zuul/certs"
  ];
  zuul-extraOptions = ["--add-host=zookeeper-1:${config.containers.zookeeper-1.localAddress}"];
in {
  systemd.services."create-zuul-certs" = {
    description = "Create certs for zuul";
    script = ''
      set -euo pipefail
      ${pkgs.libressl}/bin/openssl req \
        -nodes \
        -newkey \
        rsa:4096 \
        -keyout zuul-key.pem \
        -out zuul.csr \
        -subj "/C=SE/CN=zuul" \

      ${pkgs.libressl}/bin/openssl x509 \
        -req \
        -in zuul.csr \
        -CA ${config.systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cacert.pem \
        -CAkey ${config.systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cakey.pem \
        -CAcreateserial \
        -days 365 \
        -sha256 \
        -out zuul-cert.pem


      cp ${config.systemd.services."create-zookeeper-ca".serviceConfig.WorkingDirectory}/cacert.pem cacert.pem
      chmod 644 zuul-cert.pem
      chmod 640 zuul-key.pem
      chown -R ${zuul-certs-cfg.user}:${zuul-certs-cfg.user} .
    '';
    wantedBy = [
      "multi-user.target"
      "docker-zuul-scheduler-0.service"
      "docker-zuul-web-0.service"
      "docker-zuul-executor-0.service"
      "docker-zuul-merger-0.service"
    ];
    unitConfig = {
      Before = [
        "multi-user.target"
        "docker-zuul-scheduler-0.service"
        "docker-zuul-web-0.service"
        "docker-zuul-executor-0.service"
        "docker-zuul-merger-0.service"
      ];
      ConditionPathExists = "!${zuul-certs-cfg.path}/zuul-cert.pem";
    };
    serviceConfig = {
      User = "0";
      Type = "oneshot";
      StateDirectory = zuul-certs-cfg.path;
      WorkingDirectory = "/var/lib/${zuul-certs-cfg.path}";
      RemainAfterExit = true;
    };
  };
  virtualisation.oci-containers.containers = {
    zuul-web-0 = {
      image = "zuul/zuul-web";
      volumes = zuul-volumes;
      extraOptions = zuul-extraOptions;
    };
    zuul-scheduler-0 = {
      image = "zuul/zuul-scheduler";
      volumes = zuul-volumes;
      extraOptions = zuul-extraOptions;
    };
    zuul-executor-0 = {
      image = "zuul/zuul-executor";
      volumes = zuul-volumes;
      extraOptions = zuul-extraOptions;
    };
    zuul-merger-0 = {
      image = "zuul/zuul-merger";
      volumes = zuul-volumes;
      extraOptions = zuul-extraOptions;
    };
  };
}
