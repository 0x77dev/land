{ ... }: {
  imports = [
    ./networking.nix
    ./storage.nix
    ./monitoring.nix
    ./databases.nix
    ./media.nix
    ./analytics.nix
    ./ipfs.nix
    ./arr.nix
    ./github-runner.nix
    ./smarthome.nix
  ];
}
