{config, pkgs, lib, ...}:
{
  # For mount.cifs, required unless domain name resolution is not needed.
  environment.systemPackages = [ pkgs.davfs2 ];
  users.groups.davfs2 = {};
  users.users.davfs2 = {
    group = "davfs2";
    isSystemUser = true;
  };
  fileSystems."/var/lib/minio" = {
      device = "https://u343362-sub4.your-storagebox.de";
      fsType = "davfs";
      options = ["rw,file_mode=0660,dir_mode=0700" "0" "0"];
  };
}
