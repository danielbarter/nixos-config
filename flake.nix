{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixos-generators.url = "github:nix-community/nixos-generators";
    hosts.url = "github:StevenBlack/hosts";

    # unify nixpkgs across inputs
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    hosts.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
      self, nixpkgs, nixos-generators, hosts
  } @ outputs-args:

    let core-modules = [
          ./base.nix
          ./networking.nix
          ./users.nix
          ./nix-config.nix
        ];

        # passthrough whether system has a gui or not
        # currently only used to decide which emacs package
        # to install
        module-args = { gui ? true }: {
          flake-outputs-args = outputs-args;
          flake = self;
          gui = gui;
        };

        platform = {build, host}: {...}: {
          nixpkgs.buildPlatform.system = build;
          nixpkgs.hostPlatform.system = host;
        };

    in {
      nixosConfigurations = {
        jasper = nixpkgs.lib.nixosSystem rec {
          specialArgs = module-args;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./jasper.nix
              ./sway-gui.nix
              ./intel-gpu.nix
            ];
        };

        punky = nixpkgs.lib.nixosSystem rec {
          specialArgs =  module-args { gui = false; };
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./punky.nix
              hosts.nixosModule {
                networking.stevenBlackHosts = {
                  enable = true;
                  blockFakenews = true;
                  blockGambling = true;
                  blockPorn = true;
                  blockSocial = true;
                };
              }
              ./intel-gpu.nix
            ];
        };

        rupert = nixpkgs.lib.nixosSystem rec {
          specialArgs =  module-args;
          system = "x86_64-linux";
          modules = core-modules ++
            [
              ./rupert.nix
            ];
        };
      };


      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };

          x86_64-vm = iso: pkgs.writeScriptBin "x86_64-run-nixos-vm" ''
            #!${pkgs.runtimeShell}
            ${pkgs.qemu_full}/bin/qemu-kvm \
            -smp $(nproc) \
            -cdrom ${iso}/iso/nixos.iso \
            -nographic \
            -m 8G
          '';

          aarch64-vm = iso: let
            drive-flags = "format=raw,readonly=on";
            efi-flash = "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw";
          in pkgs.writeScriptBin "aarch64-run-nixos-vm" ''
            #!${pkgs.runtimeShell}
            ${pkgs.qemu_full}/bin/qemu-system-aarch64 \
            -machine virt \
            -cpu cortex-a57 \
            -m 2G \
            -smp 4 \
            -nographic \
            -drive if=pflash,file=${efi-flash},${drive-flags} \
            -drive file=${iso}/iso/nixos.iso,${drive-flags}
            '';

        in {

          # before building run ./utils/pack_etc_nixos.sh
          x86_64-replicant-iso = nixos-generators.nixosGenerate rec {
            specialArgs = module-args;
            format = "iso";
            system = "x86_64-linux";
            modules = core-modules ++ [
              ./replicant.nix
              # we are probably going to be running on some intel chip,
              # so make sure that we have VA-API drivers so firefox is happy
              ./intel-gpu.nix
              ./sway-gui.nix
            ];
          };

          # before building run ./utils/pack_etc_nixos.sh
          aarch64-replicant-iso = nixos-generators.nixosGenerate rec {
            specialArgs = module-args { gui = false; };
            system = "x86_64-linux";
            format = "iso";
            modules = core-modules ++ [
              ./replicant.nix
              (platform {build = system; host = "aarch64-linux";})

              # ideally, we would also like to cross compile a gui, but many components
              # of the linux desktop stack are packaged in an ad-hoc way, which makes
              # reliable cross compilation a hard.
            ];
          };


          x86_64-replicant-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-iso;
          aarch64-replicant-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-iso;
        };
    };
}
