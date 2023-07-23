{ config, pkgs, system, nixpkgs, emacs-overlay,  ... }:

let emacs-pkgs = import nixpkgs {
      inherit system;
      overlays = [ emacs-overlay.overlays.default ];
    };
in {

  environment.systemPackages = with pkgs; [
    (emacs-pkgs.emacs-git.override {
      withPgtk = true;
    })
    aspell
    aspellDicts.en
    cmake               # cmake autocomplete and emacs mode.
 ];


}
