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
  hostName = ???;
  initialVersion = ???;
  packages = with pkgs; [
    sway-host-specific-hook
  ];
}

