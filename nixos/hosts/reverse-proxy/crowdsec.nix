{ config, pkgs, inputs, ... }: {
  imports = [
    inputs.crowdsec.nixosModules.crowdsec
      inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
  ];

  nixpkgs.overlays = [inputs.crowdsec.overlays.default];

  sops.secrets = {
    "crowdsec/enrollKeyFile" = {
      owner = config.systemd.services.crowdsec.serviceConfig.User;
      group = config.systemd.services.crowdsec.serviceConfig.Group;
    };
    "crowdsec/firewallBouncer/EnvironmentFile" = {
      owner = config.systemd.services.crowdsec.serviceConfig.User;
      group = config.systemd.services.crowdsec.serviceConfig.Group;
    };
  };

  services.crowdsec = let
    yaml = (pkgs.formats.yaml {}).generate;
    acquisitions_file = yaml "acquisitions.yaml" {
      source = "journalctl";
      journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
      labels.type = "syslog";
    };
  in {
    enable = true;
    enrollKeyFile = config.sops.secrets."crowdsec/enrollKeyFile".path;
    allowLocalJournalAccess = true;
    settings = {
      crowdsec_service.acquisition_path = acquisitions_file;
      api.server = {
        listen_uri = "127.0.0.1:8080";
      };
    };
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
    settings = {
      api_key = "ctuZ5rd+ilyCLQOXlViNeNavS+9wHvFs6Dnbmgm17LE";
      api_url = "http://127.0.0.1:8080";
    };
  };
  systemd.services.crowdsec-firewall-bouncer.serviceConfig = {
    EnvironmentFile = config.sops.secrets."crowdsec/firewallBouncer/EnvironmentFile".path;
    PassEnvironment = "API_KEY";
  };
}
