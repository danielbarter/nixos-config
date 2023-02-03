{ config, pkgs, nixpkgs, system, ... }:
let

  pkgsEmacsOverlay =  import nixpkgs {
    inherit system;
    # overlay for cutting edge emacs
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/d1ea6872b199edc680917a7248b596e532297538.tar.gz;
        sha256 = "sha256:04d95r51wmz7w742lpx5xb4ww4c8xbpn3mkfm8sss06f7gw2zic7";
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
