{
  lib,
  ...
}:
{
  networking.hostName = lib.mkDefault "muscle";

  snowfallorg.users."0x77" = {
    create = true;

    home = {
      enable = true;
      path = "/home/0x77";

      config = { };
    };
  };
}
