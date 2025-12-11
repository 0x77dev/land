_:
{ lib }:
{
  openssh.authorizedKeys.keys = lib.mkDefault [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhgGGgMgUf9UysNVEb41g+niAkaqYTMx3CXgxcFMPSb cardno:24_377_114"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLwgUmfKE8SDO7FJ4tUT4rPS/OraXAmrqQYj47zeF8LUWpJc12few20m4IcFkpC9/+C+O1LdSwNCL4I243JwKMQ= cardno:24_377_114"
  ];
}
