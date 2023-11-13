{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    davfs2
  ];
  deployment = {
    keys = {
      "davfs2-secret" = {
        name = "secrets";
        destDir = "/etc/davfs2";
        keyCommand = ["bws-get" "davfs2"];
        user = "root";
        group = "root";
        permissions = "0600";
      };
    };
  };
  users.groups.davfs2 = {};
  users.users.davfs2 = {
    group = "davfs2";
    isSystemUser = true;
  };
  fileSystems."/var/lib/davfs2" = {
      device = "https://u343362.your-storagebox.de";
      fsType = "davfs";
      options = ["rw,file_mode=0660,dir_mode=0755" "0" "0"];
  };
}

