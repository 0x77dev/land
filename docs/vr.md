# Vision Pro VR runbook

`muscle` provides nixpkgs ALVR 20.14.1 (`alvr-org/ALVR`
`a9f6542fa507a841f40ab4f3fcb531427cd02550`), Steam's NixOS FHS
environment, 32-bit graphics, PipeWire, GameMode, and `vulkaninfo`. The
visionOS App Store 20.14.5 client embeds the same 20.14.1 protocol family at
`e3fd448029c795b1b2d5835c84c6588bf01bae0d`.

The baseline works with both M2 and M5 Vision Pro. Use HEVC 8-bit at 90 Hz;
qualify M5-only AV1 or 120 Hz separately.

ALVR 20.14.1 has no supported preset file or CLI import mechanism. Nix does
not manage `~/.config/alvr/session.json`; dashboard settings, client trust,
certificates, pairing, Steam manifests and beta selection, driver
registration, and OpenVR/OpenXR runtime files all remain mutable and
ALVR/Steam-owned.

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
5. Start `alvr_dashboard` from the normal GNOME session. Enter the recommended
   profile below in the dashboard. Do not wrap it or SteamVR in Gamescope,
   MangoHud, OBS capture, or another Vulkan layer during qualification.
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
the safe baseline intentionally has no custom fork. Controller poses retain
the upstream client correction and server offset; sticks, face buttons,
analog trigger/grip, and generic haptics map through the Quest profile.
Adaptive triggers are unavailable, PS buttons may be reserved by visionOS,
and dedicated touch/proximity semantics are incomplete. Expect Oculus labels
and verify both controllers in SteamVR's controller test before starting a
game.

## Diagnostic and target profiles

Change one setting at a time and keep SteamVR global resolution at 100%.

Enter this recommended daily profile in ALVR's dashboard:

- HEVC Main 8-bit at explicit 90 Hz.
- High resolution: 2592 pixels per eye, or 5184 combined, with aspect-derived
  height; SteamVR global resolution remains user-owned at 100%.
- Medium fixed foveation: 0.66 x 0.60 center, centered, with 6 x 6 edge ratios.
- NVENC P3, low-latency tuning, temporal AQ, CBR rate control, no multipass,
  weighted prediction, 10-bit, or HDR. ALVR 20.14.1's Linux encoder does not
  forward the session multipass selector to FFmpeg.
- Adaptive throughput 40-170 Mbit/s targeting 90% of measured throughput,
  with 8 ms network and 30 ms decoder limits.
- UDP, 1400-byte packets, maximum socket buffers, two video queue entries,
  two buffering frames, and no DSCP.
- PipeWire game audio on, microphone off; passthrough, face/body/hand tracking,
  client foveation, async compute, and async reprojection off.
- Quest 2 headset and Touch controller emulation with automatic mappings and
  upstream pose offsets.

For a conservative diagnostic run, use ALVR's built-in controls temporarily:

- H.264 8-bit, 90 Hz, Medium resolution, 50-80 Mbit/s.
- High fixed foveation and P1/Speed.
- Microphone, HDR, 10-bit encoding, progressive mode, and extra overlays off.

There is no custom profile switcher and Nix does not reassert dashboard
changes. ALVR's `adapter_index` is Windows-only in this path. On Linux, ALVR
encodes on the Vulkan device UUID captured from SteamVR. Current Vulkan GPU0 is
`0000:c1:00.0`,
`26ea6764-15b9-101f-f6dd-dcddb317519b`, which drives the primary Samsung.
Confirm that UUID in ALVR logs and NVIDIA telemetry; there is no supported
ALVR per-session Linux adapter selector. Never set global Vulkan, NVIDIA, or
CUDA device variables.

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
- Server and client near 90 FPS, game-render p95 below 11.11 ms, encode p95
  below 9 ms, decode below 8 ms, and ALVR network latency normally below 5 ms.
- A 30-minute native SteamVR session without disconnects, audio underruns,
  repeating latency spikes, or visible IDR recovery.
- A 45-60 minute thermal run without falling to 45 or 30 FPS.

Only then test lighter foveation, a higher adaptive ceiling, Ultra resolution,
M5 AV1, 120 Hz, microphone, or non-native VR injectors.

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
