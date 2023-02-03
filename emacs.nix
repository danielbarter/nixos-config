{ config, pkgs, system, nixpkgs, emacs-overlay, ... }:

let emacs-pkgs = import nixpkgs {
      inherit system;
      overlays = [ emacs-overlay.overlays.default ];
    };

in {
  environment.systemPackages = with pkgs; [
    (emacs-pkgs.emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode.
    cmake
    aspell
    aspellDicts.en
  ];

}
