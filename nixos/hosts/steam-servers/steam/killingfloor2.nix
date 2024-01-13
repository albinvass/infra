{pkgs, lib, fetchSteam, ...}: let
	# Set to {id}-{branch}-{password} for betas.
	steam-app = "232130";
in {
	users.users.killingfloor2 = {
		isSystemUser = true;
		# Valheim puts save data in the home directory.
		home = "/var/lib/killingfloor2";
		createHome = true;
		homeMode = "750";
		group = "killingfloor2";
	};

	users.groups.killingfloor2 = {};

	systemd.services.killingfloor2 = {
		wantedBy = [ "multi-user.target" ];

		# Install the game before launching.
		wants = [ "steam@${steam-app}.service" ];
		after = [ "steam@${steam-app}.service" ];

		serviceConfig = {
			ExecStart = lib.escapeShellArgs [
				"/var/lib/steam-app-${steam-app}/killingfloor2_server.x86_64"
				"-nographics"
				"-batchmode"
				"-savedir" "/var/lib/killingfloor2/save"
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
			User = "killingfloor2";
			WorkingDirectory = "~";
		};
		environment = {
			# linux64 directory is required by Valheim.
			LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:${pkgs.glibc}/lib";
		};
	};
}
