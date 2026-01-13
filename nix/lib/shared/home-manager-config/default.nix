_:
{ lib }:
{
  backupFileExtension = lib.mkDefault "backup";
  useUserPackages = lib.mkDefault true;
}
