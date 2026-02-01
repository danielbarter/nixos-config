{ nixpkgs, hosts}: let

  # common modules + better platform support for all physical machines
  nixosSystem = { build, host, modules }:
   nixpkgs.lib.nixosSystem {
    system = build;
    modules = modules ++ [
      {
        nixpkgs.buildPlatform.system = build;
        nixpkgs.hostPlatform.system = host;
      }

      { nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; }

      ./base.nix
      ./nix-config.nix
      ./users.nix
      ./packages.nix
      ./ssh-config.nix
    ];
  };

in {
  tarball = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ./tarball.nix
      { nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; }
      ./base.nix
      ./nix-config.nix
      ./packages.nix
    ];
  };

  jasper = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./jasper.nix
      ./gui.nix
      ./intel-gpu.nix
     ];
  };

  punky = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./punky.nix
      ./headless-networking.nix
      ./static-bond-interface.nix
    ];
  };


  blaze = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
       hosts.nixosModule
       ./blaze.nix
       ./headless-networking.nix
     ];
  };


  x86_64-replicant = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./replicant.nix
      ./intel-gpu.nix
      ./gui.nix
      
    ];
  };

  x86_64-replicant-minimal  = nixosSystem {
    build = "x86_64-linux";
     host = "x86_64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyS0"];}
    ];
  };

  aarch64-replicant-minimal = nixosSystem {
    build = "x86_64-linux";
     host = "aarch64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyAMA0"];}
    ];
  };

  riscv64-replicant-minimal = nixosSystem {
    build = "x86_64-linux";
     host = "riscv64-linux";
     modules = [
      ./replicant.nix
      { boot.kernelParams = ["console=ttyS0"];}
    ];
  };

}
