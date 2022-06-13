{pkgs, ...}:

{
  fileSystems."/home/danielbarter/scratch" =
    { device = "/dev/disk/by-uuid/c9eddc97-7162-46b7-af6b-85069271b722";
      fsType = "ext4";
    };


  services.logind = {
    killUserProcesses = false;
    extraConfig = "HandlePowerKey=suspend";
  };

}
