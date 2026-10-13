# Mario Strikers Charged for PortMaster

**Work in progress. Not playable yet on handhelds** (see Status below).

This repository turns [yannicksuter/mscharged-port](https://github.com/yannicksuter/mscharged-port), the native PC port of Mario Strikers Charged (Wii) built from its decompilation, into a PortMaster port for Linux handhelds (aarch64, Mali and similar GPUs). It holds only patches, build scripts, tests and the PortMaster launcher. No game data is included: players supply their own USA disc (R4QE01, revision 1) as `.rvz` or `.iso`.

Test device: Anbernic RG35XX H (Allwinner H700, Mali-G31, about 1 GB RAM, Knulli).

## What the patches do

The upstream port renders through Dawn (Vulkan). Handheld GPUs here have no Vulkan, so the renderer is replaced by an OpenGL ES 3 backend for [encounter/aurora](https://github.com/encounter/aurora), taken from [bmdhacks/aurora](https://github.com/bmdhacks/aurora) (MIT), written for Dusklight on the same device.

| Series | Applies to | Purpose |
|---|---|---|
| `patches/aurora-gles` | Aurora | The GLES backend, merged onto the port's Aurora pin and its own Aurora patches |
| `patches/aurora-glesfix` | Aurora | Rendering fixes found by the Vulkan against GLES comparison |
| `patches/aurora-gpu` | Aurora | GPU memory and speed on the device (texture streaming, census), in progress |
| `patches/aurora-pm` | Aurora | Device build fixes, lock free address lookup, faster THP movie decoder |
| `patches/port-gles` | port | Selects the GLES backend (CMake option, `gles-release` preset) |
| `patches/port-pm` | port | Per second performance log (`MSCHARGED_PERF_LOG=1`), PortMaster build fixes |
| `patches/port-perf` | port | Cheaper emulated audio (AX/DSP), audio work on a worker thread, opt in movie zoom |
| `patches/decomp-pm` | game decomp | Compiler compatibility for the older aarch64 toolchain |
| `patches/test-capture` | Aurora and port | Test only frame capture and virtual clock, never shipped |
| `patches/aurora-gles-wip` | none | Unfinished experiments kept for reference, not built |

Audio and video changes are verified to give the same output as the original code (bit identical audio over a full match, pixel identical THP frames).

## Building

PC (GLES build, for testing):

```
./prepare.sh
tools/gles_build.sh
```

aarch64 PortMaster zip (cross build in Docker, glibc 2.30 or newer on the device):

```
build/00_image.sh
build/01_fetch.sh
build/10_sdl.sh
build/20_build.sh
build/30_package.sh
build/40_verify.sh
```

The zip lands in `dist/mscharged.zip`. The SDL3 library shipped on the device is the shim in `vendor/sdl3-shim` (see its README for where it comes from).

## Installing on a device

Unzip into the ports folder, copy the disc image into `ports/mscharged/`, and start "Mario Strikers Charged" from the Ports menu. Settings for the launcher (render resolution, movie zoom, performance log) are in `ports/mscharged/launch.cfg`.

## Tests

* `tests/compare`: deterministic Vulkan against GLES frame comparison on PC, with results in its README.
* `tests/pc`: offscreen boot and scripted match runs (Xvfb for GLES, headless gamescope for Vulkan).
* `tests/thp`: equivalence test of the THP decoder against the original.

## Status

Boots and plays on PC with GLES. On the RG35XX H it boots and runs the intro; a GPU texture leak during movies and GPU throughput are being fixed, so it is not playable on a device yet.

## Licenses

The upstream port is CC0. Aurora and the GLES backend are MIT. SDL is zlib. The license texts shipped with the port are in `port/mscharged/licenses` (copied in at packaging time).
