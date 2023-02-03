{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    hosts.url = github:StevenBlack/hosts;
    emacs-overlay.url = github:nix-community/emacs-overlay;
  };

  outputs = { self, nixpkgs, hosts, emacs-overlay }:

    {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem {
          # we pass in nixpkgs and emacs-overlay and do the actual
          # overlaying inside the emacs module, otherwise build artifacts
          # do not get cached correctly
          specialArgs = { inherit nixpkgs emacs-overlay; };
          system = "x86_64-linux";
          modules =
            [
              ./base.nix
              ./networking.nix
              ./emacs.nix
              ./users.nix
              ./lingering.nix
              ./pass.nix
              ./home-setup.nix
              ./jasper.nix
              ./gui.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit nixpkgs emacs-overlay; };
          system = "x86_64-linux";
          modules =
            [
              ./base.nix
              ./networking.nix
              ./emacs.nix
              ./users.nix
              ./lingering.nix
              ./pass.nix
              ./home-setup.nix
              ./punky.nix
              hosts.nixosModule { networking.stevenBlackHosts.enable = true; }
            ];
        };

        rupert = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit nixpkgs emacs-overlay; };
          system = "x86_64-linux";
          modules =
            [
              ./base.nix
              ./networking.nix
              ./emacs.nix
              ./users.nix
              ./lingering.nix
              ./pass.nix
              ./home-setup.nix
              ./rupert.nix
            ];
        };
      };
    };
}
