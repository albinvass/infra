{ config, pkgs, ... }:
{
  sops.secrets = {
    "discord-server-status/EnvironmentFile" = {
      owner = "root";
      group = "root";
      mode = "0600";
    };
  };
  systemd.services.discord-server-status = {
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      EnvironmentFile = config.sops.secrets."discord-server-status/EnvironmentFile".path;
      ExecStart =
      let
        script = pkgs.writeScriptBin "discord-server-status" /* bash */ ''
          #!${pkgs.bash}/bin/bash
          service="$1"
          ${pkgs.discord-sh}/bin/discord.sh \
            --webhook-url "$WEBHOOK_URL" \
            --username "Server Status" \
            --text "Server $service crashed"
        '';
      in "${script}/bin/discord-server-status %I";
    };
  };
}
