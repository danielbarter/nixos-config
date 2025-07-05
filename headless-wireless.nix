{pkgs,...}:
{
  
  networking.wireless.iwd = {

    enable = true;
    settings = {
      General = {
        # attempt to find a better AP every 10 seconds (default is 60)
        RoamRetryInterval = "10";
      };
    };
  };

  environment.systemPackages = [ pkgs.iw ];
  # give wireless cards time to turn on
  systemd.services.iwd.serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
}
