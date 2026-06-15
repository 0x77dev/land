_: {
  # Shared LAN-agent model set for Spark and Muscle. Every entry must fit the
  # smaller Muscle budget (2x RTX 6000 Ada, 48 GB each). Qwen3-Coder-Next is the
  # long-context coding/agent pick: q4_K_M is ~51.74 GB and leaves enough room
  # for a 256K q8 KV cache; q8_0 is ~84.81 GB and is too tight at full context.
  agentModels = [
    "qwen3-coder-next:q4_K_M"
    "huihui_ai/Qwen3.6-abliterated:35b-Claude-4.7"
    "gpt-oss:20b"
  ];
}
