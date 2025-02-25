{ config, lib, pkgs, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in
{
  programs.kitty = {
    enable = true;
    package = unstable.kitty;
    font = {
      name = "JetBrains Mono";
      size = 14;
    };
  };

  # Create the theme files for automatic OS appearance switching
  # Fetch the theme files directly from the kitty-themes repository
  home.file = {
    # Dark mode theme
    "dark-theme-kitty" = {
      target = ".config/kitty/dark-theme.auto.conf";
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/themes/GitHub_Dark.conf";
        sha256 = "sha256-23D48bQgQJjcRk6kfD3lBxaXvWzCxPnTYGjDDdluuCQ=";
      };
    };

    # Light mode theme
    "light-theme-kitty" = {
      target = ".config/kitty/light-theme.auto.conf";
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/themes/GitHub_Light.conf";
        sha256 = "sha256-AtxguOM3Cfyvco2uyFiCA57OcVab/B5ch1cYGySdzpw=";
      };
    };

    "no-preference-theme-kitty" = {
      target = ".config/kitty/no-preference-theme.auto.conf";
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kovidgoyal/kitty-themes/master/themes/GitHub_Dark.conf";
        sha256 = "sha256-23D48bQgQJjcRk6kfD3lBxaXvWzCxPnTYGjDDdluuCQ=";
      };
    };
  };
}
