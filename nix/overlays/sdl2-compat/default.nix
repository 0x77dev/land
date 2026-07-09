_: _final: prev: {
  # cudaSupport hosts rebuild sdl2-compat from source, where the test suite's
  # surface_testSaveLoadBitmap case fails in the sandbox (everything else
  # passes). Skip checks; the binary cache variant isn't tested here either.
  sdl2-compat = prev.sdl2-compat.overrideAttrs { doCheck = false; };
}
