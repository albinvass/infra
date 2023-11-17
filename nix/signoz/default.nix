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
    signoz-query-service = { config }: {
      options = {};
      config = {};
    };
  };
  packages = {
      signoz-query-service = pkgs.buildGoModule rec {
        pname = "SigNoz";
        version = "0.34.0";
        vendorSha256 = "sha256-fCpIfPN3dBjTRAUlD15OKKMSl10aGafyd0RK3Eqtlfo=";
        checkPhase = false;
        # Onyl build query-service
        preBuild = ''
          cd pkg/query-service
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
