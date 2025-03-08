{
  inputs = {

    # flake inputs can be overriden eg
    # --override-input nixpkgs /home/danielbarter/nixpkgs
    nixpkgs.url = "github:danielbarter/nixpkgs/9a416feab31c62141d5a2f14f4108f5d6e9858c0";
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

      nixosConfigurations =
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

        in
        {
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

        };

      packages."x86_64-linux" =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };

          x86_64-vm-params = {
            script-name = "x86_64-run-nixos-vm";
            qemu-invocation = "${pkgs.qemu}/bin/qemu-kvm";
            efi-flash = "${pkgs.OVMF.fd}/FV/OVMF_CODE.fd";
          };

          aarch64-vm-params = {
            script-name = "aarch64-run-nixos-vm";
            qemu-invocation = "${pkgs.qemu}/bin/qemu-system-aarch64 -cpu cortex-a57 -machine virt";
            efi-flash = "${pkgs.pkgsCross.aarch64-multiplatform.OVMF.fd}/FV/AAVMF_CODE.fd";
          };

          riscv64-vm-params = {
            script-name = "riscv64-run-nixos-vm";
            qemu-invocation = "${pkgs.qemu}/bin/qemu-system-riscv64 -machine virt";
            efi-flash = "${pkgs.pkgsCross.riscv64.OVMF.fd}/FV/RISCV_VIRT_CODE.fd";
          };


          vm = arch-params: image: pkgs.writeScriptBin arch-params.script-name ''
            #!${pkgs.runtimeShell}
            cp ${image}/image.raw /dev/shm/image.raw
            chmod +w /dev/shm/image.raw

            ${arch-params.qemu-invocation} \
            -drive file=${arch-params.efi-flash},readonly=on,if=pflash \
            -drive file=/dev/shm/image.raw,format=raw \
            -smp 4 \
            -nographic \
            -m 4G
            
            rm /dev/shm/image.raw
          '';

          x86_64-vm = vm x86_64-vm-params;
          aarch64-vm = vm aarch64-vm-params;
          riscv64-vm = vm riscv64-vm-params;
        in
        {

          # before building run ./utils/pack_etc_nixos.sh
          x86_64-replicant-image = self.nixosConfigurations.x86_64-replicant.config.system.build.image;
          x86_64-replicant-minimal-image = self.nixosConfigurations.x86_64-replicant-minimal.config.system.build.image;
          aarch64-replicant-minimal-image = self.nixosConfigurations.aarch64-replicant-minimal.config.system.build.image;
          riscv64-replicant-minimal-image = self.nixosConfigurations.riscv64-replicant-minimal.config.system.build.image;

          x86_64-replicant-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-image;
          x86_64-replicant-minimal-vm = x86_64-vm self.packages."x86_64-linux".x86_64-replicant-minimal-image;
          aarch64-replicant-minimal-vm = aarch64-vm self.packages."x86_64-linux".aarch64-replicant-minimal-image;
          riscv64-replicant-minimal-vm = riscv64-vm self.packages."x86_64-linux".riscv64-replicant-minimal-image;
        };
    };
}
