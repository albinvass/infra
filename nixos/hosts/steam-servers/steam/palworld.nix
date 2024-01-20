{ config, pkgs, lib, ... }:
{
  users.groups.palworld = {};
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
  };

  systemd.services.palworld = let
    palworld-server = pkgs.stdenv.mkDerivation rec {
      name = "palworld";
      src = pkgs.fetchSteam {
        inherit name;
        appId = "2394010";
        depotId = "2394012";
        manifestId = "4603741190199642564";
        hash = "sha256-NEnskCOl031yb0+jmsWkFHMZVVrRzM4BLLVZGko1Jk8=";
      };

      # Skip phases that don't apply to prebuilt binaries.
      dontBuild = true;
      dontConfigure = true;
      dontFixup = true;

      buildInputs = with pkgs; [];
      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
      ];
      installPhase = ''
        runHook preInstall

        ls -al
        mkdir -p $out
        cp -r ./* $out/
        #chmod +x $out/valheim_server.x86_64
        #patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/valheim_server.x86_64

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
        platforms = ["x86_64-linux"];
      };
    };
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = let
        script = pkgs.writeScriptBin "palworld-server" /* bash */ ''
          #!${pkgs.bash}/bin/bash
          ${palworld-server}/valheim_server.x86_64 \
            -nographics \
            -batchmode \
            -savedir /var/lib/valheim/save \
            -name steam-servers.dev.albinvass.se \
            -port "2456" \
            -world Dedicated \
            -password "''${VALHEIM_SERVER_PASSWORD}" \
            -public 1 \
            -backups 1
        '';
      in {
      ExecStart = [
        "${script}/bin/palworld-server"
      ];
      Nice = "-5";
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
  };
}
