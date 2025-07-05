{lib, pkgs,...}: { 
  programs.firefox.enable = true;

  # enable bluetooth
  hardware.bluetooth.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true; 
  };

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;



  environment.systemPackages = with pkgs; [
    dracula-theme # gtk theme
    adwaita-icon-theme # default gnome icons
    wl-clipboard
  ];

  # configure GTK themes
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            cursor-size = lib.gvariant.mkInt32 24;
            cursor-theme = "Dracula-cursors";
            gtk-theme = "Dracula";
            icon-theme = "Adwaita";
          };

          "org/gnome/desktop/input-sources" = {
            xkb-options = ["caps:swapescape"]; 
          };

        };
      }
    ];
  };

}
