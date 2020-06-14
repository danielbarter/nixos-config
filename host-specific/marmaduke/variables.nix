{pkgs, ...}:

{
  hostName = "marmaduke";
  wirelessInterface = "wlp2s0";
  initialVersion = "20.03";
  packages = with pkgs; [ light # control backlight
             ];
}

