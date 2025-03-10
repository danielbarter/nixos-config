{ nixpkgs, hosts}: let

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
      ./packages.nix
      ./networking.nix
      ./users.nix
      ./nix-config.nix
    ];
  };

in {
  jasper = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      ./jasper.nix
      ./sway-gui.nix
      ./sound.nix
      ./intel-gpu.nix
    ];
  };

  punky = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      hosts.nixosModule
      ./punky.nix
      ./intel-gpu.nix
      ./sound.nix
    ];
  };

  rupert = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [ ./rupert.nix ];
  };


  x86_64-replicant = nixosSystem {
    build = "x86_64-linux";
    host = "x86_64-linux";
    modules = [
      # we are probably going to be running on some intel chip,
      # so make sure that we have VA-API drivers so firefox is happy
      ./intel-gpu.nix
      ./sway-gui.nix
      ./sound.nix
      ./replicant.nix
      
    ];
  };

  x86_64-replicant-minimal  = nixosSystem {
    build = "x86_64-linux"; host = "x86_64-linux"; modules = [./replicant.nix];
  };
  aarch64-replicant-minimal = nixosSystem {
    build = "x86_64-linux"; host = "aarch64-linux"; modules = [./replicant.nix];
  };
  riscv64-replicant-minimal = nixosSystem {
    build = "x86_64-linux"; host = "riscv64-linux"; modules = [./replicant.nix];
  };

}
