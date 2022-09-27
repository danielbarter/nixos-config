{pkgs, ...}:
let sway-host-specific-hook = pkgs.writeTextFile {
    name = "sway-host-specific-hook";
    destination = "/bin/sway-host-specific-hook";
    executable = true;
    text = ''
      '';
    };
in
{
  hostName = "rupert";
  initialVersion = "20.09";
  packages = [ sway-host-specific-hook ];
}
