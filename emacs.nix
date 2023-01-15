{ config, pkgs, ... }:
let

  pkgsEmacsOverlay =  import <nixpkgs> {

    # overlay for cutting edge emacs
    config = config.nixpkgs.config;
    overlays = [
      (import (builtins.fetchTarball {
        url = https://github.com/nix-community/emacs-overlay/archive/800685a0ad5dfa94d6e3fffb5ffa1a208ad8c76a.tar.gz;
      }))
    ];
  };

in
{
  environment.systemPackages = with pkgs; [
    (pkgsEmacsOverlay.emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode. Remove cmake binary so it
    # doesn't interfere with local environments
    ( cmake.overrideAttrs (finalAttrs: previousAttrs: { postInstall = "rm $out/bin/*";}))
    aspell
    aspellDicts.en
  ];

}
