# list of packages in my user environment
# refresh with nix-env --remove-all -if /etc/nixos/danielbarterEnv.nix

with import <nixpkgs> {

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
[
    wget
    htop
    firefox-wayland
    google-chrome
    emacsPgtk
    zathura
    aspell
    aspellDicts.en
    (pass.withExtensions (exts: [exts.pass-otp]))
    python38
    nix-serve
    steam
    nmap
    zip
    unzip
    radare2
    fzf
    zbar
]
