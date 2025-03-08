{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:NixOs/nixpkgs/9a416feab31c62141d5a2f14f4108f5d6e9858c0";
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
