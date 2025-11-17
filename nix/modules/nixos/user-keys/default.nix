{
  lib,
  namespace,
  config,
  ...
}:
let
  userNames = builtins.attrNames config.snowfallorg.users;
  userConfig = lib.${namespace}.shared.user-config { inherit lib; };
in
{
  users.users = lib.mkMerge (
    map (userName: {
      ${userName} = userConfig;
    }) userNames
  );
}
