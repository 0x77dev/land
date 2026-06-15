_: {
  # Shared LAN-agent model set for Spark and Muscle. Every entry must fit the
  # smaller Muscle budget (2x RTX 6000 Ada, 48 GB each); current registry layer
  # sizes are ~23.94 GB for Qwen3.6-35B-A3B and ~13.79 GB for gpt-oss:20b,
  # leaving room for a 128K quantized KV cache and one parallel slot.
  agentModels = [
    "huihui_ai/Qwen3.6-abliterated:35b-Claude-4.7"
    "gpt-oss:20b"
  ];
}
