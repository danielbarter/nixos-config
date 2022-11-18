{pkgs, ...}:

{
  hostName = "jasper";
  initialVersion = "21.11";
  packages = with pkgs; [
    powertop
    (android-studio.override { tiling_wm = true;})
    jetbrains.idea-community
    godot
    element-desktop-wayland    # matrix client
    steam
  ];
}

