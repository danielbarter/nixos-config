{ pkgs, ...}:
{

  environment.systemPackages = [ pkgs.mpg123 ];

  # enable bluetooth
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;

    wireplumber = {
      enable = true;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/10-bluez-seat.conf" ''
          wireplumber.profiles = {
            main = {
              monitor.bluez.seat-monitoring = disabled
            }
          }
       '')
      ];
    };
  };
}
