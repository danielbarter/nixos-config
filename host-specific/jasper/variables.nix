{pkgs, ...}:

{
  hostName = "jasper";
  initialVersion = "21.11";
  packages = with pkgs; [
    powertop
    element-desktop-wayland    # matrix client
    steam
  ];
}

