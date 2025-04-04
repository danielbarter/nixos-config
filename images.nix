{ nixosConfigurations, nixpkgs }: let
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
in rec {
  
# before building run ./utils/pack_etc_nixos.sh
  x86_64-replicant-image = nixosConfigurations.x86_64-replicant.config.system.build.image;
  x86_64-replicant-minimal-image = nixosConfigurations.x86_64-replicant-minimal.config.system.build.image;
  aarch64-replicant-minimal-image = nixosConfigurations.aarch64-replicant-minimal.config.system.build.image;
  riscv64-replicant-minimal-image = nixosConfigurations.riscv64-replicant-minimal.config.system.build.image;

  x86_64-replicant-vm = x86_64-vm x86_64-replicant-image;
  x86_64-replicant-minimal-vm = x86_64-vm x86_64-replicant-minimal-image;
  aarch64-replicant-minimal-vm = aarch64-vm aarch64-replicant-minimal-image;
  riscv64-replicant-minimal-vm = riscv64-vm riscv64-replicant-minimal-image;
}
