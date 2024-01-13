{pkgs, lib, steam-fetcher, ...}:
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

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
      ];
      installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r ./* $out/
        chmod +x $out/valheim_server.x86_64
        patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $out/valheim_server.x86_64

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
		serviceConfig = {
			ExecStart = lib.escapeShellArgs [
				"${valheim-server}/valheim_server.x86_64"
				"-nographics"
				"-batchmode"
				"-savedir" "/var/lib/valheim/save"
				"-name" "steam-servers.dev.albinvass.se"
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
			LD_LIBRARY_PATH = "${valheim-server}/:${pkgs.glibc}/lib:${pkgs.libz}/lib";
			SteamAppId = "892970";
		};
	};
}
