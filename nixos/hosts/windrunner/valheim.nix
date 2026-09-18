{ config, ... }:
let
  gamePort = 2456;
  queryPort = 2457;
  stateDir = "/var/lib/valheim";
in
{
  sops.secrets = {
    # env-file syntax, currently just:
    #   SERVER_PASS=<password>
    # Min 5 chars, and it must not occur inside SERVER_NAME or WORLD_NAME
    # below or the server refuses to start.
    "valheim/env" = { };
  };

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0750 root root -"
    "d ${stateDir}/config 0750 root root -"
    "d ${stateDir}/data 0750 root root -"
  ];

  virtualisation.oci-containers.containers = {
    "valheim" = {
      # 1.3.0 (:latest as of 2026-09-18). ghcr.io/lloesche/valheim-server is
      # now a legacy mirror of this repo. Pinning the image does not freeze the
      # game server itself — the container updates Valheim in place via
      # SteamCMD on UPDATE_INTERVAL, so this digest only needs bumping for
      # image changes.
      image = "ghcr.io/community-valheim-tools/valheim-server@sha256:c43502d3b28c8d341f5362f365deb4802018bda9fc49f98c7631b099f597eb49";
      ports = [
        "${toString gamePort}:${toString gamePort}/udp"
        "${toString queryPort}:${toString queryPort}/udp"
      ];
      volumes = [
        "${stateDir}/config:/config" # worlds, backups, admin/ban lists
        "${stateDir}/data:/opt/valheim" # game install, re-downloadable
      ];
      environmentFiles = [ config.sops.secrets."valheim/env".path ];
      environment = {
        SERVER_NAME = "windrunner";
        WORLD_NAME = "Midgard";
        SERVER_PUBLIC = "true";
        TZ = config.time.timeZone;

        # 64-bit Steam IDs, space separated.
        ADMINLIST_IDS = "76561197969564382";

        # Check for game updates every 15 min, but wait for an empty server.
        UPDATE_INTERVAL = "900";
        RESTART_IF_IDLE = "true";

        # Rolling world snapshots into /var/lib/valheim/config/backups.
        BACKUPS = "true";
        BACKUPS_INTERVAL = "3600";
        BACKUPS_MAX_COUNT = "12";
        BACKUPS_MAX_AGE = "3";
        BACKUPS_IF_IDLE = "false";
      };
      # Lets the server raise its own thread priority; reduces stutter.
      extraOptions = [ "--cap-add=SYS_NICE" ];
    };
  };

  # The server flushes the world to disk on SIGTERM. systemd's default stop
  # timeout can cut that short on a large world, which is the usual cause of a
  # save rolling back hours.
  systemd.services.podman-valheim.serviceConfig.TimeoutStopSec = 120;

  # Reached directly via a router port-forward rather than the frp relay the
  # HTTP services use: relaying game traffic through Helsinki cost ~100ms, and
  # frp carries UDP inside its TCP control connection, so loss on that leg
  # stalls the stream. valheim.albinvass.se is an A record at the home IP.
  networking.firewall.allowedUDPPorts = [
    gamePort
    queryPort
  ];
}
