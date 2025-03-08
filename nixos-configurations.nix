{ nixpkgs, hosts }:
let
  core-modules = [
    ./base.nix
    ./packages.nix
    ./networking.nix
    ./users.nix
    ./nix-config.nix
    { nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ]; }
  ];

  replicant-core-modules = core-modules ++ [ ./replicant.nix ];

  replicant-minimal = { system, host }: nixpkgs.lib.nixosSystem {
    system = system;
    modules = replicant-core-modules ++ [
      {
        nixpkgs.buildPlatform.system = system;
        nixpkgs.hostPlatform.system = host;
      }
    ];
  };

in {
  jasper = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = core-modules ++ [
      ./jasper.nix
      ./sway-gui.nix
      ./sound.nix
      ./intel-gpu.nix
    ];
  };

  punky = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = core-modules ++ [
      ./punky.nix
      hosts.nixosModule
      {
        networking.stevenBlackHosts = {
          enable = true;
          blockFakenews = true;
          blockGambling = true;
          blockPorn = true;
          blockSocial = true;
        };
      }
      ./intel-gpu.nix
      ./sound.nix
    ];
  };

  rupert = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = core-modules ++ [ ./rupert.nix ];
  };


  x86_64-replicant = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = replicant-core-modules ++ [
      # we are probably going to be running on some intel chip,
      # so make sure that we have VA-API drivers so firefox is happy
      ./intel-gpu.nix
      ./sway-gui.nix
      ./sound.nix
    ];
  };

  x86_64-replicant-minimal  = replicant-minimal {system = "x86_64-linux"; host = "x86_64-linux";};
  aarch64-replicant-minimal = replicant-minimal {system = "x86_64-linux"; host = "aarch64-linux";};
  riscv64-replicant-minimal = replicant-minimal {system = "x86_64-linux"; host = "riscv64-linux";};

}
