# I use user environments to install packages from overlays and local nixpkgs
# messy to do it in configuration.nix
# refresh with nix-env --remove-all -if /etc/nixos/danielbarterEnv.nix

let
  pkgsEmacsOverlay =  import <nixpkgs> {
    # emacs overlay to get pureGTK emacs
    # current mainline emacs isn't wayland native
    # this is a problem if you are using multiple screens with different resolutions
    # this community overlay adds developer versions of emacs with wayland support
    # amoung other things.
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
      }))
    ];
  };

  pkgsLocal = import /home/danielbarter/nixpkgs {};
  in [
    pkgsEmacsOverlay.emacsPgtk
    (pkgsLocal.android-studio.override { tiling_wm = true;})
  ]
