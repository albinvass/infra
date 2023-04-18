{config, pkgs, lib, ...}:
{
  services.plex.enable = true;
  services.plex.dataDir = "/opt/data/plex";
  services.plex.openFirewall = true;
  services.plex.group = "media";
  users.groups."media".gid = 10001;
}
