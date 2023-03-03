{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    hosts.url = github:StevenBlack/hosts;
  };

  outputs = { self, nixpkgs, hosts }:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./lingering.nix
          ./pass.nix
          ./home-setup.nix
        ];
    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          # we pass in nixpkgs so we use nixpkgs.outPath to
          # set $NIX_PATH
          specialArgs = { inherit nixpkgs; };
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./gui.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs = { inherit nixpkgs; };
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./punky.nix
              hosts.nixosModule { networking.stevenBlackHosts.enable = true; }
            ];
        };

        rupert = nixpkgs.lib.nixosSystem rec {
          specialArgs = { inherit nixpkgs; };
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };
      };
    };
}
