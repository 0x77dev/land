{
  pkgs,
  namespace,
  ...
}:
{
  home.packages = with pkgs.${namespace}; [
    tx-02-variable
  ];

  # Required to autoload fonts from packages
  fonts.fontconfig.enable = true;
}
