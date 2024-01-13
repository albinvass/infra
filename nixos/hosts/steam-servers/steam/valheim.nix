{pkgs, lib, fetchSteam, ...}: let
	# Set to {id}-{branch}-{password} for betas.
	steam-app = "896660";
  valheim-server = pkgs.stdenv.mkDerivation rec {
      name = "some-server";
      src = fetchSteam {
        inherit name;
        appId = "896660";
        depotId = "896661";
        manifestId = "252049227837324070";
        hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
      };

      # Skip phases that don't apply to prebuilt binaries.
      dontBuild = true;
      dontConfigure = true;
      dontFixup = true;

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
      ];
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r \
          # list of files at the top level to copy
          $out

        # You may need to fix permissions on the main executable.
        chmod +x $out/valheim_server.x86_64

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
	users.users.valheim = {
		isSystemUser = true;
		# Valheim puts save data in the home directory.
		home = "/var/lib/valheim";
		createHome = true;
		homeMode = "750";
		group = "valheim";
	};

	users.groups.valheim = {};

	systemd.services.valheim = {
		wantedBy = [ "multi-user.target" ];

		# Install the game before launching.
		#wants = [ "steam@${steam-app}.service" ];
		#after = [ "steam@${steam-app}.service" ];

		serviceConfig = {
			ExecStart = lib.escapeShellArgs [
				"${valheim-server}/valheim_server.x86_64"
				"-nographics"
				"-batchmode"
				"-savedir" "/var/lib/valheim/save"
				"-name" "play.albinvass.se"
				"-port" "2456"
				"-world" "Dedicated"
				"-password" "YOUR PASSWORD HERE!!!"
				"-public" "1"
				"-backups" "1"
			];
			Nice = "-5";
			PrivateTmp = true;
			Restart = "always";
			User = "valheim";
			WorkingDirectory = "~";
		};
		environment = {
			# linux64 directory is required by Valheim.
			LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:${pkgs.glibc}/lib:${pkgs.libz}/lib";
			SteamAppId = "892970";
		};
	};
}
