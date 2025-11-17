{
  lib,
  ...
}:
let
  userName = "mykhailo";
in
{
  networking.hostName = lib.mkDefault "muscle";

  snowfallorg.users.${userName} = {
    create = true;

    home = {
      enable = true;
      path = "/home/${userName}";

      config = { };
    };
  };
}
