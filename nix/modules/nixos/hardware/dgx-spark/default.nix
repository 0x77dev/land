{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.dgx-spark;

  # Pinned NVIDIA NV-Kernels source + the NVIDIA-generated structured kernel
  # config, vendored from graham33/nixos-dgx-spark (kernel 6.17.1).
  kernelSource = import ./nvidia-kernel-source.nix;
  dgxKernelConfig = import (./. + "/nvidia-dgx-spark-${kernelSource.nvidiaKernelVersion}.nix") {
    inherit lib;
  };

  # Upstream pins to NVIDIA's maintained 6.17 branch via a `linux_6_17 =
  # linux_latest` alias overlay; we skip the alias and use `linux_latest`
  # directly. The source, version, and config are fully overridden below, so
  # the base package version is irrelevant.
  baseKernel = pkgs.linux_latest;

  nvidiaKernelPatches = [
    {
      name = "rust-gendwarfksyms-fix";
      patch = ./rust-gendwarfksyms-fix.patch;
    }
  ];

  nvidiaKernel = pkgs.linuxPackagesFor (
    baseKernel.override {
      argsOverride = {
        src = kernelSource.mkNvidiaKernelSource pkgs;
        version = "${kernelSource.nvidiaKernelVersion}-nvidia";
        modDirVersion = kernelSource.nvidiaKernelVersion;
        kernelPatches = nvidiaKernelPatches;
      };

      enableCommonConfig = true;
      ignoreConfigErrors = true;

      structuredExtraConfig =
        dgxKernelConfig
        // (with lib.kernel; {
          SECURITY_APPARMOR_BOOTPARAM_VALUE = freeform "1";
          SECURITY_APPARMOR_RESTRICT_USERNS = lib.mkForce yes;

          USB_STORAGE = yes;
          USB_UAS = yes;
          OVERLAY_FS = yes;

          UEVENT_HELPER = no;

          UBUNTU_HOST = no;
        });
    }
  );

  # Strip embedded references to the kernel `-dev` output from the NVIDIA .ko
  # files. The nvidia kernel-modules build declares `allowedReferences = [ ]`,
  # but the .ko files end up with __FILE__-derived header paths pointing into
  # the kernel-dev store path, so the closure check fails. This only affects
  # non-stock (patched aarch64) kernels, so it is gated on `useNvidiaKernel`.
  scrubKernelDevRefs =
    drv:
    drv.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        if [ -d "$out/lib/modules" ]; then
          find $out/lib/modules -name '*.ko' -print0 \
            | xargs -0 -r ${pkgs.removeReferencesTo}/bin/remove-references-to \
                -t ${nvidiaKernel.kernel.dev}
        fi
      '';
    });
in
{
  options.hardware.dgx-spark = {
    enable = lib.mkEnableOption "NVIDIA DGX Spark (GB10) hardware support";

    useNvidiaKernel = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use NVIDIA's custom DGX Spark kernel (NV-Kernels rev pinned in
        `nvidia-kernel-source.nix`, built with the structured config in
        `nvidia-dgx-spark-${kernelSource.nvidiaKernelVersion}.nix`) instead of
        the standard NixOS kernel. A full build requires an aarch64-linux
        builder; the Flox cache only covers CUDA userspace, not the kernel.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      allowUnfree = true;
      cudaSupport = true;
      # GB10 reports compute capability sm_121 (12.1); 12.0 is included for
      # broader Blackwell-family (sm_120) compatibility, matching upstream.
      cudaCapabilities = [
        "12.0"
        "12.1"
      ];
    };

    boot = {
      kernelPackages = lib.mkIf cfg.useNvidiaKernel nvidiaKernel;

      kernelParams = [
        "console=tty1"
        # Module-autoload kill switches for kernel CVEs with no upstream patch:
        #   algif_aead  — CVE-2026-31431 (AF_ALG AEAD local privesc)
        #   esp4, esp6, rxrpc — CVE-2026-43284 / CVE-2026-43500 ("Dirty Frag")
        # `module_blacklist=` makes request_module() refuse modprobe entirely,
        # robust against both autoload and explicit modprobe — unlike
        # `boot.blacklistedKernelModules`, which only blocks alias autoloads.
        "module_blacklist=algif_aead,esp4,esp6,rxrpc"
      ];

      blacklistedKernelModules = [
        "nouveau"
        "r8169"
        "coresight_etm4x"
      ];
    };

    hardware = {
      enableRedistributableFirmware = true;
      graphics.enable = true;
      nvidia = {
        modesetting.enable = true;
        open = true;
        nvidiaPersistenced = true;
        nvidiaSettings = true;
        package =
          let
            prod = config.boot.kernelPackages.nvidiaPackages.production;
          in
          if cfg.useNvidiaKernel then
            prod
            // {
              open = scrubKernelDevRefs prod.open;
              mod = scrubKernelDevRefs prod.mod;
            }
          else
            prod;
      };
      nvidia-container-toolkit.enable = true;
    };

    services = {
      xserver.videoDrivers = [ "nvidia" ];

      # Firmware updates via LVFS. NVIDIA publishes DGX Spark firmware there.
      fwupd.enable = true;
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia
      iperf3
      ethtool
      rdma-core
    ];
  };
}
