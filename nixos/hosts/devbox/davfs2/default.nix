{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ davfs2 ];
  sops.secrets = {
    "davfs2/secrets" = {
      owner = "root";
      group = "root";
      mode = "0600";
      path = "/etc/davfs2/secrets";
    };
  };

  users.groups.davfs2 = { };
  users.users.davfs2 = {
    group = "davfs2";
    isSystemUser = true;
  };

  fileSystems."/var/lib/davfs2" = {
    device = "https://u343362.your-storagebox.de";
    fsType = "davfs";
    options = [
      "rw,file_mode=0660,dir_mode=0755"
      "0"
      "0"
    ];
  };
}
