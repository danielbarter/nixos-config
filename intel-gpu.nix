{ pkgs, ... }:
{
  # intel_gpu_top
  environment.systemPackages = [ pkgs.intel-gpu-tools ];

  # enabling opencl and VA-API GPU drivers
  hardware.opengl = {
    enable = true;
    extraPackages = [
      pkgs.intel-compute-runtime
      pkgs.intel-vaapi-driver
      pkgs.libvdpau-va-gl
      pkgs.intel-media-driver
    ];
  };
}
