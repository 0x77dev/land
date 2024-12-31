{ ... }: {
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    # Allow netdata to run smbstatus command as root
    extraConfig = ''
      netdata ALL=(root) NOPASSWD: ${pkgs.samba}/bin/smbstatus
    '';
  };
}
