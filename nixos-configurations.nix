{ nixpkgs, hosts, voxtype, sopsModule }: let
  nixosSystem = import "${nixpkgs}/nixos/lib/eval-config.nix";

  # common modules + better platform support for all physical machines
  nixosSystemCommon = { build, host, modules, managedSecrets ? false }:
   nixosSystem {
    system = build;
    modules = modules ++ [
      {
        nixpkgs.buildPlatform.system = build;
        nixpkgs.hostPlatform.system = host;
      }

      { nix.nixPath = [ "nixpkgs=${nixpkgs}" ]; }
      { secretsManagement.enable = managedSecrets; }

      ./base.nix
      ./nix-config.nix
      ./users.nix
      ./ssh-config.nix
      ./secrets.nix
      sopsModule
    ];
  };

in {
  container = nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./container.nix
      { nix.nixPath = [ "nixpkgs=${nixpkgs}" ]; }
    ];
  };

  jasper = nixosSystemCommon {
    managedSecrets = true;
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      voxtype
      { services.voxtype.enable = true; }
      ./jasper.nix
      ./gui.nix
      ./intel-gpu.nix
      ./packages.nix
     ];
  };

  punky = nixosSystemCommon {
    managedSecrets = true;
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./punky.nix
      ./headless-networking.nix
      ./static-bond-interface.nix
      ./packages.nix
    ];
  };


  blaze = nixosSystemCommon {
    managedSecrets = true;
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
       hosts
       ./blaze.nix
       ./headless-networking.nix
       ./wireguard-interface.nix
      ./packages.nix
     ];
  };


  x86_64-replicant = nixosSystemCommon {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./replicant.nix
      ./intel-gpu.nix
      ./gui.nix
      ./packages.nix
      
    ];
  };

  x86_64-replicant-minimal  = nixosSystemCommon {
    build = "x86_64-linux";
     host = "x86_64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyS0"];}
    ];
  };

  aarch64-replicant-minimal = nixosSystemCommon {
    build = "x86_64-linux";
     host = "aarch64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyAMA0"];}
    ];
  };

  riscv64-replicant-minimal = nixosSystemCommon {
    build = "x86_64-linux";
     host = "riscv64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyS0"];}
    ];
  };

}
