{pkgs, ...}:

let calibrate-display = pkgs.writeTextFile {
    name = "calibrate_display";
    destination = "/bin/calibrate_display";
    executable = true;
    text = ''
      #! ${pkgs.bash}/bin/bash
       swaymsg output eDP-1 scale 1.5
      '';
    };
in
{
  hostName = "jasper";
  wirelessInterface = "wlp170s0";
  initialVersion = "21.11";
  packages = with pkgs; [
    light # control backlight
    calibrate-display
    powertop
  ];
}

