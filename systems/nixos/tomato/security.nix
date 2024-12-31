{ pkgs, ... }: {
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    # Allow netdata to run monitoring commands as root
    extraConfig = ''
      # Samba monitoring
      netdata ALL=(root) NOPASSWD: ${pkgs.samba}/bin/smbstatus
      # Fail2ban monitoring
      netdata ALL=(root) NOPASSWD: ${pkgs.fail2ban}/bin/fail2ban-client status
      netdata ALL=(root) NOPASSWD: ${pkgs.fail2ban}/bin/fail2ban-client status *
      # IPFS monitoring
      netdata ALL=(root) NOPASSWD: ${pkgs.ipfs}/bin/ipfs stats *
      # Process monitoring
      netdata ALL=(root) NOPASSWD: ${pkgs.procps}/bin/ps -C * -O pcpu,pmem,comm
      netdata ALL=(root) NOPASSWD: ${pkgs.iproute2}/bin/ss -tupl
    '';
  };
}
