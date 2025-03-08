{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:danielbarter/nixpkgs/11f89bdae007b15c611cdbb0268effe091162814";
    hosts.url = "github:StevenBlack/hosts";

    # unify nixpkgs across inputs
    hosts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      hosts,
    }:
    {

      nixosConfigurations = import ./nixos-configurations.nix { inherit nixpkgs hosts;};
      packages."x86_64-linux" = import ./images.nix {
        nixosConfigurations = self.nixosConfigurations;
        inherit nixpkgs;
      };
    };
}
