{ pkgs, ... }:

{
  # TODO: add TX-02 from Berkeley Mono
  # home.packages = with pkgs; [
  #   (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  #   jetbrains-mono
  # ];

  fonts.fontconfig.enable = true;
}
