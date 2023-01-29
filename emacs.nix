{ config, pkgs, ... }:
let

  pkgsEmacsOverlay =  import <nixpkgs> {

    # overlay for cutting edge emacs
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/d1ea6872b199edc680917a7248b596e532297538.tar.gz;
      }))
    ];
  };

in
{
  environment.systemPackages = with pkgs; [
    (pkgsEmacsOverlay.emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode.
    cmake
    aspell
    aspellDicts.en
  ];

}
