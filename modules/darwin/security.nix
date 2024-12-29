{ ... }:

{
  # Enable Touch ID authentication for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Disable console access from login window for security
  system.defaults.loginwindow.DisableConsoleAccess = true;

  # Disable shutdown/sleep options on login screen
  system.defaults.loginwindow.ShutDownDisabled = true;
  system.defaults.loginwindow.SleepDisabled = true;
  system.defaults.loginwindow.ShutDownDisabledWhileLoggedIn = true;

  # Don't show user list on login screen, require username entry
  system.defaults.loginwindow.SHOWFULLNAME = true;

  # Disable automatic login
  system.defaults.loginwindow.autoLoginUser = null;
}
