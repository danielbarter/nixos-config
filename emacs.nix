{ config, pkgs, nixpkgs, emacs-overlay, ... }:

let pkgs-emacs-overlay-resolver = { nixpkgs, emacs-overlay }:
      import nixpkgs {
        system = "x86_64-linux";
        overlays = [ emacs-overlay.overlays.default ];
      };

in {
  environment.systemPackages = with pkgs; [
    ((pkgs-emacs-overlay-resolver {inherit nixpkgs emacs-overlay;}).emacsGit.override {
      withPgtk = true;
    })
    # cmake autocomplete and emacs mode.
    cmake
    aspell
    aspellDicts.en
  ];

}
