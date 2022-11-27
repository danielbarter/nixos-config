{pkgs, ...}:

{
  hostName = "jasper";
  initialVersion = "21.11";
  packages = with pkgs; [
    powertop
    android-studio
    jetbrains.idea-community
    element-desktop-wayland    # matrix client
    steam
  ];
}

