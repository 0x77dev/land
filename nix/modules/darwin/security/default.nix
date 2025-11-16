_: {
  # Enable Touch ID authentication for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults.loginwindow = {
    # Disable console access from login window for security
    DisableConsoleAccess = true;

    # Disable shutdown/sleep options on login screen
    ShutDownDisabled = true;
    SleepDisabled = true;
    ShutDownDisabledWhileLoggedIn = true;

    # Don't show user list on login screen, require username entry
    SHOWFULLNAME = true;

    # Disable automatic login
    autoLoginUser = null;
  };
}
