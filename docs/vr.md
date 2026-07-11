# Vision Pro VR runbook

`muscle` provides ALVR 20.14.1, Steam's NixOS FHS environment, 32-bit
graphics, PipeWire, GameMode, and `vulkaninfo`. Nix does not own SteamVR,
client trust, controller pairing, OpenVR/OpenXR runtime files, or ALVR's
`session.json`.

The baseline works with both M2 and M5 Vision Pro. Use HEVC 8-bit at 90 Hz;
qualify M5-only AV1 or 120 Hz separately.

## Network prerequisite

Choose the VR interface, subnet, and firewall migration before connecting a
dedicated AP. The current host firewall is disabled, so no interface isolation
is presently enforced.

The intended E7 contract is:

- Vision Pro and `muscle` on the same layer-2 network.
- `muscle` wired to the AP and Vision Pro on a dedicated 5 GHz SSID.
- Fixed 80 MHz channel, clear line of sight, and client isolation disabled.
- No dependency on 6 GHz, Wi-Fi 7, 320 MHz, or MLO; Vision Pro does not use
  those E7 capabilities.

ALVR needs TCP and UDP 9943 and 9944 between the headset and host. UDP 9942 is
only for optional OSC, and TCP 8082 is the dashboard; neither belongs in the
headset firewall baseline. The NixOS VR module can scope 9943/9944 to a chosen
interface later, but refuses that setting while the system firewall is
disabled.

## First setup

1. With Steam stopped, keep a private backup of its `config` directory and
   `steamapps/appmanifest_250820.acf` if the manifest already exists. Do not
   copy or delete the game library.
2. Install SteamVR, AppID 250820, through Steam.
3. In SteamVR properties, select the `previous` beta while the current Linux
   compositor regression remains. At research time this resolved to 2.12.14;
   Valve can retarget the branch, so record the installed build before
   updating it.
4. Install **ALVR 20.14.5** from the visionOS App Store. This client remains in
   the 20.14.1 host protocol family; do not substitute a v21/nightly host.
5. Start `alvr_dashboard` from the normal GNOME session. Do not wrap it or
   SteamVR in Gamescope, MangoHud, OBS capture, or another Vulkan layer during
   qualification.
6. Use ALVR's installation controls to register the packaged driver and launch
   SteamVR. The dashboard registers its current immutable Nix store path and
   removes stale ALVR registrations when it launches SteamVR. Repeat this step
   after an ALVR package upgrade; do not hard-code a store path.
7. On Vision Pro, grant Local Network and required tracking permissions, leave
   microphone and experimental face/passthrough features off, launch ALVR, and
   explicitly trust the client in the dashboard.
8. If discovery fails, first confirm same-L2 connectivity, Local Network
   permission, and disabled AP client isolation. Keep the microphone off and
   add the client IP manually only after the network address is known.

SteamVR remains the OpenXR runtime for ALVR sessions. Select it through
SteamVR only when an OpenXR title needs it; do not enable Monado or write a
global OpenXR runtime manifest.

## PSVR2 Sense on Vision Pro

This path requires visionOS 26 or newer. Controllers pair directly to Vision
Pro, not to Linux:

- Left: hold **PS + Create**.
- Right: hold **PS + Options**.

Start with ALVR's Quest 2 Touch emulation for broad SteamVR compatibility.
Stock ALVR 20.14.1 does not provide the newer dedicated PSVR2 host profile, and
the safe baseline intentionally has no custom fork. Expect Oculus labels and
incomplete PSVR2 touch/proximity semantics. Verify both controllers in
SteamVR's controller test before starting a game.

## Diagnostic and target profiles

Change one setting at a time and keep SteamVR global resolution at 100%.

Initial transport smoke test:

- H.264 8-bit, 90 Hz, Medium resolution, 50-80 Mbit/s.
- High fixed foveation and the fast encoder preset.
- Microphone, HDR, 10-bit encoding, progressive mode, and extra overlays off.

Daily acceptance target:

- HEVC 8-bit, explicit 90 Hz.
- High resolution, P3/Balanced encoder, Medium fixed foveation.
- Adaptive 20-150 Mbit/s or a measured constant 120-150 Mbit/s.
- UDP, packet size 1400, no DSCP override, at most two buffered frames.

ALVR has a session-level `adapter_index`, but its Linux UI hides the setting.
Leave index 0 unchanged until `vulkaninfo`, ALVR logs, and NVIDIA telemetry
identify the GPU actually rendering and encoding. If it is wrong, adjust only
ALVR's mutable session setting; never set global Vulkan or CUDA GPU variables.

Safe diagnostics:

```bash
vulkaninfo --summary
nvidia-smi --query-gpu=index,pci.bus_id,uuid,name --format=csv,noheader
nvidia-smi dmon -s u
wpctl status
```

After SteamVR is installed, inspect registrations without changing them:

```bash
"$HOME/.local/share/Steam/steamapps/common/SteamVR/bin/vrpathreg.sh" show
```

## Acceptance

Before increasing quality, require:

- At least 200 Mbit/s measured local throughput.
- Median host latency at most 3 ms, p95 at most 5 ms, jitter at most 1 ms, and
  no packet loss during the test.
- Server and client near 90 FPS, game-render p95 below 11.11 ms, encode below
  5 ms, decode below 8 ms, and ALVR network latency normally below 5 ms.
- A 30-minute native SteamVR session without disconnects, audio underruns,
  repeating latency spikes, or visible IDR recovery.
- A 45-60 minute thermal run without falling to 45 or 30 FPS.

Only then test lighter foveation, 180-210 Mbit/s, Ultra resolution, M5 AV1, 120
Hz, microphone, or non-native VR injectors.

## Rollback

Exit SteamVR before changing drivers or branches.

- Use ALVR's installation panel to unregister its driver; do not edit
  `openvrpaths.vrpath` directly.
- Restore SteamVR's prior branch through Steam and verify the installed build.
- Restore only the private configuration backups made before setup.
- Preserve `~/.config/alvr`, `~/.config/openvr`, `~/.config/openxr`, and the
  Steam library unless a specific file has been diagnosed.
- Roll back the NixOS generation if the host package/module change is at fault.

## Official PSVR2 headset

Sony's official PSVR2 PC adapter requires Windows 10 or 11, SteamVR, and the
PlayStation VR2 App. Sony ships only Windows kernel, USB, and OpenVR drivers;
native Steam, Proton, Wine, and Steam Linux Runtime cannot load them.

Use a separate Windows dual boot for full PSVR2 headset and Sense support. This
NixOS baseline does not enable Monado, VFIO, libvirt, Sony firmware tooling, or
PSVR2 USB ownership.
