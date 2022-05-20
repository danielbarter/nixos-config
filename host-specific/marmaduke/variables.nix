{pkgs, ...}:

{
  hostName = "marmaduke";
  initialVersion = "20.03";
  packages = with pkgs; [ light # control backlight
             ];
}

