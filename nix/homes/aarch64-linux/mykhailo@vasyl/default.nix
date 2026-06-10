{
  lib,
  namespace,
  ...
}:
let
  shared = lib.${namespace}.shared.home-config { inherit lib; };
in
{
  # Mykhailo's home on vasyl: the same shared home modules he uses everywhere,
  # so the VM feels like his other machines (shell, prompt, aliases, editor,
  # direnv). Thin by design — shared modules carry the content.
  programs.home-manager.enable = true;

  inherit (shared) home;
  modules.home = shared.modules.home // {
    git = {
      enable = true;
      # No YubiKey inside the VM: commits stay unsigned. Authorship is still
      # Mykhailo (git module + the system gitconfig with the Assisted-by
      # trailer); "vasyl" is only the machine/persona name.
      signing = false;
    };
  };
}
