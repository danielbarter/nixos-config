{pkgs,... }: {
  systemd.services.llama-cpp = let
    llama-vulkan = pkgs.llama-cpp.override {vulkanSupport = true;};
    model_file = "/ML/deepseek_r1_distill_qwen_14b.gguf";
    layers = "49";
    network_config = "--host 0.0.0.0 --port 80";
  in {
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${llama-vulkan}/bin/llama-server -m ${model_file} -ngl ${layers} ${network_config}";
    };
  };
}
