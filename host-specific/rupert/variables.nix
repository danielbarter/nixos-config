{pkgs, ...}:

let initializeNvidia = pkgs.writeTextFile {
      name = "initializeNvidia";
      destination = "/bin/initializeNvidia";
      executable = true;
      text = ''
         #! ${pkgs.bash}/bin/bash
         modprobe -r vfio_pci
         modprobe -r vfio_virqfd
         modprobe -r vfio_iommu_type1
         modprobe -r vfio
         echo "nvidia" > /sys/bus/pci/devices/0000:10:00.0/driver_override


         ${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi
         modprobe nvidia-uvm
         D=`grep nvidia-uvm /proc/devices | awk '{print $1}'`
         mknod -m 666 /dev/nvidia-uvm c $D 0'';
    };
in
{
  hostName = "rupert";
  initialVersion = "20.09";
  packages = [ pkgs.linuxPackages.nvidia_x11 initializeNvidia ];
}
