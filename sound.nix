{ pkgs, ...}:
{

  environment.systemPackages = [ pkgs.mpg123 ];

  # enable bluetooth
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };


}
