_: _final: prev: {
  btop = prev.btop.override { cudaSupport = prev.stdenv.hostPlatform.isLinux; };
}
