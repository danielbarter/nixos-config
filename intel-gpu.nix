{ pkgs, ... }:
{
  # intel_gpu_top
  environment.systemPackages = [ pkgs.intel-gpu-tools ];

  # enabling opencl and VA-API GPU drivers
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-vaapi-driver
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}
