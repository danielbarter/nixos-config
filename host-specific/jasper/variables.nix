{pkgs, ...}:

let sway-host-specific-hook = pkgs.writeTextFile {
    name = "sway-host-specific-hook";
    destination = "/bin/sway-host-specific-hook";
    executable = true;
    text = ''
         sleep 5
         systemctl --user start kanshi.service
      '';
    };
in
{
  hostName = "jasper";
  initialVersion = "21.11";
  packages = with pkgs; [
    light # control backlight
    sway-host-specific-hook
    powertop
  ];
}

