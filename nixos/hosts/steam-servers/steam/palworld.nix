{
  config,
  pkgs,
  lib,
  ...
}:
{
  users.groups.palworld = { };
  users.users.palworld = {
    isSystemUser = true;
    home = "/var/lib/palworld";
    createHome = true;
    homeMode = "750";
    group = "palworld";
  };

  sops.secrets = {
    "palworld-server/EnvironmentFile" = {
      owner = "palworld";
      group = "palworld";
      mode = "0600";
      restartUnits = [ "palworld.service" ];
    };
    "palworld-server/PalWorldSettings.ini" = {
      owner = "palworld";
      group = "palworld";
      mode = "0600";
      restartUnits = [ "palworld.service" ];
    };
  };

  systemd.services.palworld =
    let
      palworld-server = pkgs.stdenv.mkDerivation rec {
        name = "palworld";
        src = pkgs.fetchSteam {
          inherit name;
          appId = "2394010";
          depotId = "2394012";
          manifestId = "4190579964382773830";
          hash = "sha256-IoI5Up+Vj6Rti9BhPH2e1o+TbpjIGmcWCc5bCV8M2Ps=";
        };

        # Skip phases that don't apply to prebuilt binaries.
        dontBuild = true;
        dontConfigure = true;
        dontFixup = true;

        buildInputs = with pkgs; [ ];
        nativeBuildInputs = with pkgs; [ autoPatchelfHook ];
        installPhase = ''
          runHook preInstall

          ls -al
          mkdir -p $out
          cp -r ./* $out/
          chmod +x $out/PalServer.sh
          chmod +x $out/Pal/Binaries/Linux/PalServer-Linux-Test
          patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/Pal/Binaries/Linux/PalServer-Linux-Test

          runHook postInstall
        '';

        meta = with lib; {
          description = "Palworld dedicated server";
          homepage = "https://steamdb.info/app/2394010/";
          changelog = "https://store.steampowered.com/news/app/2394010?updates=true";
          sourceProvenance = with sourceTypes; [
            binaryNativeCode # Steam games are always going to contain some native binary component.
            binaryBytecode # e.g. Unity games using C#
          ];
          license = licenses.unfree;
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      wantedBy = [ "multi-user.target" ];
      #onFailure = [ "discord-server-status@%n.service" ];
      serviceConfig =
        let
          crashScript =
            pkgs.writeScriptBin "palworld-server-status" # bash
              ''
                #!${pkgs.bash}/bin/bash
                status="$1"
                ${pkgs.discord-sh}/bin/discord.sh \
                  --webhook-url "$WEBHOOK_URL" \
                  --username "Server Status" \
                  --text "Palworld $status"
              '';
          script =
            pkgs.writeScriptBin "palworld-server" # bash
              ''
                #!${pkgs.bash}/bin/bash
                set -euo pipefail
                PATH="''${PATH}:${pkgs.xdg-user-dirs}/bin"
                export PATH

                function notifyStart() {
                  echo "Discord: notifyStart"
                  "${crashScript}/bin/palworld-server-status" "Starting"
                }
                function notifyStop() {
                  echo "Discord: notifyStop"
                  "${crashScript}/bin/palworld-server-status" "Stopped"
                }
                function notifyPreStart() {
                  echo "Discord: notifyPreStart"
                  "${crashScript}/bin/palworld-server-status" "Initializing"
                }

                notifyPreStart
                # Palworld is stupid and wants to write to the directory it's installed in...
                ${pkgs.rsync}/bin/rsync -r "${palworld-server}/" /var/lib/palworld
                chmod -R +w /var/lib/palworld
                mkdir -p /var/lib/palworld/Pal/Saved/Config/LinuxServer
                cp ${
                  config.sops.secrets."palworld-server/PalWorldSettings.ini".path
                } /var/lib/palworld/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini

                trap 'notifyStop' EXIT

                notifyStart
                "/var/lib/palworld/Pal/Binaries/Linux/PalServer-Linux-Test" Pal
              '';
        in
        {
          ExecStart = [ "${script}/bin/palworld-server" ];
          Nice = "-5";
          MemoryMax = "12G";
          PrivateTmp = true;
          Restart = "always";
          User = "palworld";
          WorkingDirectory = "~";
          EnvironmentFile = config.sops.secrets."palworld-server/EnvironmentFile".path;
        };
      environment = {
        LD_LIBRARY_PATH = "${pkgs.steamworks-sdk-redist}/lib";
        SteamAppId = "892970";
      };
    };
  networking.firewall = {
    allowedUDPPorts = [ 8211 ];
    allowedTCPPorts = [ 25575 ];
  };
}
