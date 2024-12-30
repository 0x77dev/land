{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    neovim
    aria2
  ];
}
