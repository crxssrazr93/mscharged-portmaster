# Mario Strikers Charged for PortMaster

**Work in progress. Not playable yet on handhelds** (see Status below).

This repository turns [yannicksuter/mscharged-port](https://github.com/yannicksuter/mscharged-port), the native PC port of Mario Strikers Charged (Wii) built from its decompilation, into a PortMaster port for Linux handhelds (aarch64, Mali and similar GPUs). It holds only patches, build scripts, tests and the PortMaster launcher. No game data is included: players supply their own USA disc (R4QE01, revision 1) as `.rvz` or `.iso`.

Test device: Anbernic RG35XX H (Allwinner H700, Mali-G31, about 1 GB RAM, Knulli).

## What the patches do

The upstream port renders through Dawn (Vulkan). Handheld GPUs here have no Vulkan, so the renderer is replaced by an OpenGL ES 3 backend for [encounter/aurora](https://github.com/encounter/aurora), taken from [bmdhacks/aurora](https://github.com/bmdhacks/aurora) (MIT), written for Dusklight on the same device.

The base is yannicksuter/mscharged-port `64dcb73b` (1.0.8) with the pins unchanged (Aurora `d664382`, decomp `7a6bf165`). The previous base `d7cdfc47` (1.0.7) is kept reproducible by the git tag `base-d7cdfc47` (check out that tag to get the patches that belong to it).

| Series | Applies to | Purpose |
|---|---|---|
| `patches/aurora-gles` | Aurora, after the port's own `patches/aurora` 0001 to 0089 | The GLES backend, merged onto the port's Aurora pin and its own Aurora patches |
| `patches/aurora-glesfix` | Aurora | Rendering fixes found by the Vulkan against GLES comparison |
| `patches/aurora-pm` | Aurora | Device build fixes, lock free address lookup, faster THP movie decoder, device screenshot (`kill -USR1` the game or create `screenshot.request` in the game folder: PPM in `screenshots/`) |
| `patches/aurora-gpu` | Aurora | GPU memory and speed on the device (texture compaction, census, bounded pipeline waits, texture cache frame counter), 0001 to 0006 |
| `patches/aurora-handheld` | Aurora | `AURORA_LEAN`: no ImGui overlay and no PNG screenshots (handheld build only) |
| `patches/aurora-gpu-wip` | none | Pending GPU work, not built |
| `patches/port-gles` | port | Selects the GLES backend (CMake option, `gles-release` preset) |
| `patches/port-pm` | port | Per second performance log (`MSCHARGED_PERF_LOG=1`), PortMaster build fixes |
| `patches/port-perf` | port | Cheaper emulated audio (AX/DSP), audio work on a worker thread, opt in movie zoom |
| `patches/port-handheld` | port | `MSCHARGED_HANDHELD` option and `gles-handheld` preset: the game only build (see below) |
| `patches/decomp-pm` | game decomp | `0691` aarch64 va_list for wide printf, `0692` movie zoom option (the port's own temporary `0690` comes first) |
| `patches/test-capture` | Aurora and port | Test only frame capture and virtual clock, never shipped |

The Aurora series is assembled in this order by `tools/aurora_series.sh`: upstream 0001 to 0089 (applied by the port), then `aurora-gles`, `aurora-glesfix`, `aurora-pm`, `aurora-gpu`, then `aurora-handheld` (handheld build) or the test capture clock (test build).

Audio and video changes are verified to give the same output as the original code (bit identical audio over a full match, pixel identical THP frames).

## The handheld build

`MSCHARGED_HANDHELD=ON` (preset `gles-handheld`, used by `build/20_build.sh` for the zip) builds the game and nothing else. The PC builds with the Vulkan or GLES presets are unchanged and keep the launcher.

Left out of the handheld build:

* The launcher UI (settings pages, disc picker, About page, ImGui front end). The binary starts the game directly with `--config`, `--disc`, `--fullscreen`, `--size`, the same settings file as before.
* Wii Remote Bluetooth, HID and DolphinBar scanning (the input owner gets a driver without devices), the Dolphin save import, the window icon with its PNG.
* Aurora's ImGui overlay, FreeType, libpng and zlib, PNG screenshots.
* The extra executables (bootstrap, GX check, original credits check, session log test) and all unit tests.
* A smaller SQLite (only the plain prepared statement API that the shader and pipeline cache uses).

Compiled with one section per function and datum, so `--gc-sections` also drops unreferenced parts of the static libraries. `MSCHARGED_HANDHELD_LTO=ON` (`LTO=1 build/20_build.sh`) adds link time optimization, off by default, see the results in `docs/handheld-strip-2026-10-13.md`.

Kept on purpose: the keyboard and gamepad input (the handheld controls), the pipeline cache (SQLite, zstd), the nod disc reader, the session log, texture handling (the texture replacement code of Aurora is already a stub in the GLES series, a few calls that return nothing), Tracy (compiled out already, `TRACY_ENABLE=OFF`). Dawn and WebGPU are gone since the GLES series 0001. RmlUi and Qt are never fetched or built for the GLES backend.

## Building

PC (GLES build, for testing; the handheld variant is `PRESET=gles-handheld tools/gles_build.sh`):

```
build/01_fetch.sh
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

The zip lands in `dist/mscharged.zip`. The SDL3 library shipped on the device is the shim in `vendor/sdl3-shim` (see its README for where it comes from). `HANDHELD=0 build/20_build.sh` builds the full port (with the launcher) instead. `build/01_fetch.sh` prepares `work/xbuild-src`, the port at the pinned commit with the port and decomp patch series applied; `RESET=1` rebuilds it from the pinned commit. After editing the handheld port patch in that tree, `build/02_regen_handheld_patch.sh` writes it back to `patches/port-handheld`.

## Installing on a device

Unzip into the ports folder, copy the disc image into `ports/mscharged/`, and start "Mario Strikers Charged" from the Ports menu. Settings of the start script (render resolution, movie zoom, performance log) are in `ports/mscharged/launch.cfg`, the game settings in `ports/mscharged/mscharged.ini`.

## Tests

* `tests/compare`: deterministic Vulkan against GLES frame comparison on PC, with results in its README.
* `tests/pc`: offscreen boot and scripted match runs (Xvfb for GLES, headless gamescope for Vulkan). `tests/pc/gpu_census_run.sh` runs the menus and a match with the texture census on. Test builds with the capture hooks use their own tree: `MIRROR=1 XSRC=$PWD/work/xbuild-test TEST_CAPTURE=1 build/01_fetch.sh`, then `tests/compare/build_cmp.sh`.
* `tests/thp`: equivalence test of the THP decoder against the original.

## Status

Based on mscharged-port 1.0.8. Boots and plays on PC with GLES (also the handheld build, see `docs/handheld-strip-2026-10-13.md`). On the RG35XX H it boots and runs the intro; a GPU texture leak during movies and GPU throughput are being fixed, so it is not playable on a device yet.

## Licenses

The upstream port is CC0. Aurora and the GLES backend are MIT. SDL is zlib. The license texts shipped with the port are in `port/mscharged/licenses` (copied in at packaging time).
