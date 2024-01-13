{config, pkgs, lib, steam-fetcher, ...}:
{
  nixpkgs.overlays = [steam-fetcher.overlays.default];
	users.users.valheim = {
		isSystemUser = true;
		# Valheim puts save data in the home directory.
		home = "/var/lib/valheim";
		createHome = true;
		homeMode = "750";
		group = "valheim";
	};

	users.groups.valheim = {};

  sops.secrets = {
    "valheim-server/EnvironmentFile" = {
      owner = "valheim";
      group = "valheim";
      mode = "0600";
      restartUnits = [ "valheim.service" ];
    };
  };

	systemd.services.valheim = let
    valheim-server = pkgs.stdenv.mkDerivation rec {
      name = "valheim";
      src = pkgs.fetchSteam {
        inherit name;
        appId = "896660";
        depotId = "896661";
        manifestId = "252049227837324070";
        hash = "sha256-FZNhYn8SCuwALz5LMeOYuU2Hsc6q/pTyovqCG2wdOKs=";
      };

      # Skip phases that don't apply to prebuilt binaries.
      dontBuild = true;
      dontConfigure = true;
      dontFixup = true;

      buildInputs = with pkgs; [
        libz
      ];
      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
      ];
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r ./* $out/
        chmod +x $out/valheim_server.x86_64
        patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/valheim_server.x86_64
        patchelf --add-needed ${pkgs.libz}/lib/libz.so $out/valheim_server_Data/MonoBleedingEdge/x86_64/libmonobdwgc-2.0.so
        patchelf --add-needed ${pkgs.libz}/lib/libz.so $out/valheim_server_Data/MonoBleedingEdge/x86_64/libMonoPosixHelper.so

        runHook postInstall
      '';

      meta = with lib; {
        description = "Valheim dedicated server";
        homepage = "https://steamdb.info/app/896660/";
        changelog = "https://store.steampowered.com/news/app/896660?updates=true";
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
        script = pkgs.writeScriptBin "valheim-server" /* bash */ ''
          #!${pkgs.bash}/bin/bash
          ${valheim-server}/valheim_server.x86_64 \
            -nographics \
            -batchmode \
            -savedir /var/lib/valheim/save \
            -name steam-servers.dev.albinvass.se \
            -port 2456 \
            -world Dedicated \
            -password "''${VALHEIM_SERVER_PASSWORD}" \
            -public 1 \
            -backups 1
        '';
      in {
			ExecStart = [
				"${script}/bin/valheim-server"
			];
			Nice = "-5";
			PrivateTmp = true;
			Restart = "always";
			User = "valheim";
			WorkingDirectory = "~";
      EnvironmentFile = config.sops.secrets."valheim-server/EnvironmentFile".path;
		};
		environment = {
			LD_LIBRARY_PATH = "${pkgs.steamworks-sdk-redist}/lib";
			SteamAppId = "892970";
		};
	};
}
