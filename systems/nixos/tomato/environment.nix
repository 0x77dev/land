{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    neovim
    aria2
    aria2p
  ];
}
