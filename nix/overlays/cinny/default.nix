_: _final: prev: {
  # Vite's production build exceeds Node's default old-generation heap on the
  # hosted Darwin runners when Cinny is not yet in cache.
  cinny-unwrapped = prev.cinny-unwrapped.overrideAttrs (_old: {
    NODE_OPTIONS = "--max-old-space-size=4096";
  });
}
