{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.android-devices;

  # Android devices re-enumerate on every mode switch, and the USB product
  # identifier differs between adb, bootloader fastboot and userspace fastbootd.
  # Matching on the vendor alone is therefore the only rule that survives a
  # reboot or a mode change; matching a product would silently stop applying
  # exactly when a flashing session needs it most.
  googleVendorId = "18d1";

  # systemd tags devices for the active local seat, which does not cover a
  # remote or headless session, so group ownership carries the access that
  # matters for development over SSH. Both are applied.
  deviceGroup = "plugdev";
in
{
  options.modules.android-devices = {
    enable = lib.mkEnableOption "Android debug bridge and fastboot device access";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "mykhailo" ];
      description = ''
        Users added to the ${deviceGroup} group. Membership grants read and
        write access to Android USB nodes in every device mode, including from
        a session that does not hold the local seat; it grants no other
        privilege.
      '';
    };

    allUsbAccessories = lib.mkEnableOption ''
      access to every USB device rather than Android devices alone, so any USB
      accessory is usable without a per-device rule. This is a development
      workstation convenience: it exposes all USB devices to the local seat and
      to the ${deviceGroup} group, so it should stay off on servers and on any
      host with untrusted local users
    '';
  };

  config = lib.mkIf cfg.enable {
    # android-tools carries both adb and fastboot. Upstream dropped both
    # programs.adb and pkgs.android-udev-rules once systemd 258 began shipping
    # built-in uaccess rules, so the package and the rules are wired up here.
    environment.systemPackages = [ pkgs.android-tools ];

    services.udev.extraRules = ''
      # Google devices in adb, fastboot and fastbootd modes.
      SUBSYSTEM=="usb", ATTR{idVendor}=="${googleVendorId}", MODE="0660", GROUP="${deviceGroup}", TAG+="uaccess"
    ''
    + lib.optionalString cfg.allUsbAccessories ''
      # modules.android-devices.allUsbAccessories
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", MODE="0660", GROUP="${deviceGroup}", TAG+="uaccess"
    '';

    # The rules above reference this group, so it must exist even when no
    # package happens to declare it.
    users.extraGroups.${deviceGroup} = { };

    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ deviceGroup ];
    });
  };
}
