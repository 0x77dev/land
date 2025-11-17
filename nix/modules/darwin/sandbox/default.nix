{ lib, ... }:
{
  # Workaround for macOS sandbox size limitation
  # Error: sandbox initialization failed: data object length exceeds maximum (65535)
  # This happens with large configurations on macOS
  nix.settings.sandbox = lib.mkForce false;
}
