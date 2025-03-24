{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    neovim
    aria2
    lsof
    curl
    btop
    rclone
  ];
}
