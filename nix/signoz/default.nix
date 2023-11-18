{ inputs, pkgs, lib, ... }: rec {
  nixosModules = {
    signoz-frontend = { config, ... }: let
      cfg = config.services.signoz-frontend;
      toml = pkgs.formats.toml {};
      configFile = toml.generate "config.toml" cfg.config;
    in with lib; {
      options.services.signoz-frontend = rec {
        enable = mkEnableOption "Enable SigNoz frontend";
        package = mkOption {
          type = types.package;
          defaultText = "packages.signoz-frontend";
          description = "Set version of signoz-frontend package to use.";
          default = packages.signoz-frontend;
        };

        listen = mkOption {
          default = "[::1]:8081";
          type = types.str;
        };
        config = mkOption {
          default = { };
          type = toml.type;
        };
      };
      config = mkIf cfg.enable {
        systemd.packages = [ pkgs.static-web-server ];
        systemd.sockets.signoz-frontend = {
          wantedBy = [ "sockets.target" ];
          listenStreams = [ "" cfg.listen ];
        };
        systemd.services.signoz-frontend = {
          description = "Signoz Frontend daemon.";
          wantedBy = [ "multi-user.target" ];
          bindsTo = [ "signoz-frontend.socket" ];
          after = [ "network.target" ];
          restartIfChanged = true;

          serviceConfig = {
            DynamicUser = true;
            EnvironmentFile = [ "" ];
            ExecStart = [ "" "${pkgs.static-web-server}/bin/static-web-server --fd 0 --config-file ${configFile} --root ${cfg.package}/libexec/frontend/deps/frontend/build" ];
            Restart = "always";
          };
        };
      };
    };
    signoz-query-service = { config, ... }: let
      cfg = config.services.signoz-query-service;
      yaml = pkgs.formats.yaml {};
      prometheusCfg = yaml.generate "prometheus.yaml" cfg.prometheus;
    in with lib; {
      options.services.signoz-query-service = {
        enable = mkEnableOption "Enable SigNoz query service";
        package = mkOption {
          type = types.package;
          defaultText = "packages.signoz-frontend";
          description = "Set version of signoz-frontend package to use.";
          default = packages.signoz-query-service;
        };
        prometheus = mkOption { 
          type = yaml.type;
          default = { };
        };
        stateDirectory = mkOption {
          type = types.str;
          default = "signoz";
        };
        storage = mkOption {
          type = types.str;
          default = "clickhouse";
        };
        clickHouseURL = mkOption {
          type = types.str;
          default = "tcp://localhost:9000";
        };
      };

      config = mkIf cfg.enable {
        systemd.services.signoz-query-service = {
          description = "Signoz Query Service daemon.";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          restartIfChanged = true;

          environment = {
            SIGNOZ_LOCAL_DB_PATH = "/var/lib/${cfg.stateDirectory}/signoz.db";
            STORAGE = cfg.storage;
            ClickHouseUrl = cfg.clickHouseURL;
          };

          serviceConfig = {
            DynamicUser = true;
            EnvironmentFile = [ "" ];
            StateDirectory=cfg.stateDirectory;
            RuntimeDirectory="signoz";
            WorkingDirectory="/var/run/signoz";
            ExecStart = [ "" "${cfg.package}/bin/query-service -config ${prometheusCfg} -prefer-delta" ];
            Restart = "always";
          };
        };
      };
    };
  };
  packages = {
      signoz-query-service = pkgs.buildGoModule rec {
        pname = "SigNoz";
        version = "0.34.0";
        vendorHash = "sha256-fCpIfPN3dBjTRAUlD15OKKMSl10aGafyd0RK3Eqtlfo=";
        checkPhase = false;
        # The repo contains other go packages as well so to make sure
        # the build doesn't fail we delete everything we don't need.
        preBuild = ''
          ls -t1 | grep -vE "(vendor|pkg|go.mod)" | xargs rm -rf
        '';
        src = "${inputs.signoz-src}";
      };

      signoz-frontend = pkgs.mkYarnPackage rec {
        name = "signoz-frontend";
        src = "${inputs.signoz-src}/frontend";
        packageJson = "${src}/package.json";
        yarnLock = "${src}/yarn.lock";
        yarnNix = ./yarn.nix; 
        distPhase = "true";
        buildPhase = ''
          export HOME=$(mktemp -d)
          yarn --offline build
        '';
      };
  };
}
