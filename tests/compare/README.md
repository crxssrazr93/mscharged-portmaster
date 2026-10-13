# Vulkan versus GLES render comparison

Deterministic image comparison of the native Mario Strikers Charged port: the Vulkan reference build against the
GLES build, same disc, same scripted input, same virtual clock. PC only, fully offscreen.

## How it works

* `patches/test-capture/` holds test only code. A virtual clock Aurora patch makes game time depend on the frame
  count alone, and port hooks (CMake option `MSCHARGED_TEST_CAPTURE`) replay a scripted input file and save the
  presented frame as PNG at chosen frame numbers (`CAPTURE_FRAMES`, `CAPTURE_INPUT`, `CAPTURE_EXIT_FRAME`).
  Shipped builds never contain it.
* `build_cmp.sh` builds `work/xbuild-test/build/vk-cmp` (Vulkan) and `work/xbuild-test/build/gles-cmp` (GLES). The GLES Aurora is
  assembled by `tools/aurora_series.sh` from `patches/aurora-gles`, then `patches/aurora-glesfix`, then the virtual
  clock patch. `TAG=_x` additionally copies the binary to `mscharged_x`, and `GLESFIX=0` leaves the fix series out,
  so a baseline and a fixed binary can both be kept.
* `run.sh <vk|gles|glesgpu> <out dir> <frames> [exit frame]` makes one run. `vk` runs in a headless gamescope,
  `gles` under Xvfb with Mesa llvmpipe (software), `glesgpu` runs the GLES build on the Intel GPU inside the same
  headless gamescope as Vulkan. Environment: `INPUT`, `TAG`, `SIZE`, `INI`, `ASPECT`, `TRACE`, `TIMEOUT`.
* `diff.py A B [--out DIR] [--clusters]` prints per frame PSNR, max difference, percent of pixels above 2 and above
  16, and with `--clusters` the largest difference regions. `report.py` makes a markdown table, `crop.py` and
  `montage.py` make small crops and contact sheets for looking at results.
* Inputs: `match.input` (menus to a match, mouse and Return at fixed frames), `scenarios.txt` (frame list of the
  main run). The frame size is 640x474 in the 640x480 window.

## Commands

    tests/compare/build_cmp.sh both                       # incremental
    TAG=_base GLESFIX=0 tests/compare/build_cmp.sh gles   # baseline binary (then rebuild without GLESFIX=0)
    FR=$(cat tests/compare/scenarios.txt)
    INPUT=tests/compare/match.input tests/compare/run.sh vk work/cmp/r/vk $FR 8210
    TAG=_fix1 INPUT=tests/compare/match.input tests/compare/run.sh glesgpu work/cmp/r/ggf1 $FR 8210
    python3 tests/compare/diff.py work/cmp/r/vk/cap work/cmp/r/ggf1/cap --clusters

Intro movie frames come from a run without input (frames 1020 to 3000), the save prompt and title from frames
1760 to 1980 of the `match.input` run. A run to frame 8210 takes about 25 minutes on llvmpipe and 10 to 15 on the GPU.
Do not edit `run.sh` while a run is going (bash reads scripts incrementally).

## Determinism

Two GLES runs (Xvfb, baseline binary, 20 frames from the intro to the match) are bit identical: 20 of 20 frames,
max difference 0. Vulkan against GLES on the same GPU is bit identical for the whole intro movie and the
versus screen (frame 5300).

## Fixes in patches/aurora-glesfix

| Patch | Effect (Vulkan versus GLES, Xvfb PSNR before, after) |
|---|---|
| 0001 partial EFB copy crop offset | The GL colour target is bottom up, so a crop that does not start at the bottom copied the wrong rows. Captain select holograms were missing, the crowd and the character shadows in the match too. Frame 4200: 20.5 to 41.0 dB, 4500: 19.8 to 38.6, 4800: 18.5 to 40.6, 5100: 18.4 to 40.6, 5700: 24.9 to 40.4, 6400: 32.2 to 41.3, 6600: 35.8 to 47.1, 7000: 17.7 to 29.0, 8100: 24.3 to 32.6, 8200: 24.3 to 36.8 |
| 0002 `AURORA_GL_ANISO=<n>` | Test aid only, overrides the anisotropy maximum (0 disables) |
| 0003 `AURORA_GL_LODADD=<x>` | Test aid only, adds x to every GX texture LOD bias |

The previous agent's other wip changes were not kept: the copy dump (`AURORA_GL_COPYDUMP`) is debugging only, and the
"float steps" fix mentioned in its notes does not exist in the saved wip (nothing to keep).

## LOD bias investigation

GLSL `texture(sampler, uv, bias)` and WGSL `textureSampleBias` both add the bias to the computed LOD before the
sampler min and max LOD clamp, so the semantics match, and the shader already passes the GX bias through
`texN_size_bias.z`. Measured on the GPU (same hardware sampler as Vulkan) with `AURORA_GL_LODADD`:

| Frame | LODADD -0.5 (PSNR, % > 2) | 0 | +0.5 |
|---|---|---|---|
| 4200 | 40.0, 7.3 | 41.0, 3.5 | 39.6, 8.6 |
| 5700 | 38.9, 16.3 | 40.5, 10.2 | 37.0, 21.3 |
| 6400 | 39.8, 15.4 | 41.5, 1.3 | 39.6, 19.7 |
| 7000 | 28.9, 16.1 | 28.9, 15.9 | 28.9, 16.3 |

Bias 0 is the best everywhere, so there is no LOD offset to fix. Anisotropy is 16 on both paths (Vulkan default
config 16, GL detected maximum 16 on Mesa). The crowd still shows texture differences (see below), which are not a
bias error.

## Results (Vulkan versus GLES, final fix series)

GPU columns: GLES on the Intel GPU (same hardware as Vulkan, removes rasterizer and sampler differences). Xvfb
columns: the shipped test path on llvmpipe. Baseline is before 0001. A frame at 99.0 dB is bit identical.

| Scenario | Frame | GPU: PSNR | max | %>2 | %>16 | Xvfb llvmpipe: PSNR | %>2 | %>16 | Baseline Xvfb PSNR |
|---|---|---|---|---|---|---|---|---|---|
| intro movie | 1020 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 1200 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 1500 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 1980 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 2400 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 2700 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| intro movie | 3000 | 99.0 | 0 | 0.0 | 0.0 |  |  |  |  |
| save prompt / title | 1800 | 59.58 | 137 | 0.012 | 0.001 |  |  |  |  |
| save prompt / title | 1900 | 71.08 | 30 | 0.003 | 0.001 |  |  |  |  |
| save prompt / title | 1940 | 81.2 | 10 | 0.001 | 0.0 |  |  |  |  |
| main menu | 2200 | 62.31 | 9 | 0.171 | 0.0 | 58.0 | 0.171 | 0.0 | 58.0 |
| main menu | 2400 | 53.86 | 14 | 0.171 | 0.0 | 52.36 | 0.172 | 0.0 | 52.36 |
| main menu | 2700 | 85.79 | 6 | 0.001 | 0.0 | 57.37 | 0.004 | 0.0 | 57.37 |
| main menu | 3400 | 86.02 | 6 | 0.001 | 0.0 | 58.01 | 0.002 | 0.0 | 58.01 |
| captain / stadium select | 3800 | 84.75 | 3 | 0.0 | 0.0 | 56.2 | 0.01 | 0.0 | 56.2 |
| captain / stadium select | 4200 | 41.04 | 134 | 3.496 | 0.835 | 40.96 | 3.531 | 0.833 | 20.53 |
| captain / stadium select | 4500 | 38.67 | 137 | 3.438 | 0.867 | 38.61 | 3.461 | 0.871 | 19.8 |
| captain / stadium select | 4800 | 40.68 | 85 | 3.948 | 0.911 | 40.61 | 3.984 | 0.906 | 18.53 |
| captain / stadium select | 5100 | 40.76 | 77 | 5.497 | 0.941 | 40.58 | 5.566 | 0.942 | 18.42 |
| captain / stadium select | 5300 | 99.0 | 0 | 0.0 | 0.0 | 59.95 | 0.0 | 0.0 | 59.95 |
| match | 5700 | 40.51 | 228 | 10.231 | 0.623 | 40.35 | 10.914 | 0.624 | 24.91 |
| match | 6400 | 41.49 | 210 | 1.307 | 0.315 | 41.29 | 1.318 | 0.319 | 32.19 |
| match | 6600 | 47.87 | 91 | 0.939 | 0.133 | 47.14 | 1.001 | 0.132 | 35.76 |
| match | 7000 | 28.95 | 103 | 15.878 | 7.696 | 28.96 | 16.201 | 7.711 | 17.7 |
| match | 8100 | 32.65 | 98 | 15.048 | 3.812 | 32.62 | 15.821 | 3.824 | 24.3 |
| match | 8200 | 36.9 | 84 | 15.992 | 2.19 | 36.76 | 16.926 | 2.213 | 24.32 |

Summary per scenario (GPU columns): intro movie bit identical in all 7 frames. Save prompt and title 59 to 81 dB
(tiny animated glow differences, max 137 on under 0.01 percent of pixels). Main menu 54 to 86 dB. Captain select 39
to 41 dB with holograms. Match 29 to 48 dB. On llvmpipe the menus and movies drop to 52 to 58 dB because the software
rasterizer rounds differently, that is the only reason for the gap to the GPU columns there.

## Remaining differences, classified

| Cluster | Where | Class |
|---|---|---|
| Sparse +-1 to 15 levels over menus, movie frames on llvmpipe (up to 31) | menus, intro on Xvfb | precision (llvmpipe rasterization, mediump and interpolation rounding); gone on the GPU |
| Main menu 2200 to 2500, 0.17 percent of pixels above 2, max 14 | UI ring text and panel edges | precision (texture filtering rounding), unconfirmed |
| Captain select holograms (4200 to 5100): horizontal line pattern, signed both ways, max 130, 0.9 percent above 16 | 160x160 hologram regions | bug suspected: blurred ghost built from EFB copies, row structured difference points at a vertical half texel offset or copy filter difference in the copy and downscale path. Not isolated |
| Match 7000 Peach special: smooth halo around the wings, up to 100 levels, 7.7 percent above 16 | glow of a full screen effect | bug suspected, same copy and blur chain as the holograms (smooth gradient, no LOD sensitivity) |
| Match 5700, 6400, 8100, 8200: crowd and net texel noise, 1 to 4 percent above 16 | spectator sprites, goal net | precision or texture sampling (minification of tiny crowd sprites); not a LOD bias error (measured) |
| Match 8100: light cone top right | stadium light | unclassified, probably the same copy and blur chain |
| Edges of 3D models | everywhere | known limitation: no MSAA on GLES (and Vulkan reference config has antialiasing off, so small) |
| NBT bump, depth copies, alpha prepass, range fog | not visible in these frames | known limitations of the GLSL port, not exercised by the sampled frames |
| Per frame vertex ring overflow warning at startup ("Per-frame buffer overflow 5084012 + 179968 > 5242880" and four clamped uploads) | GLES log only, one frame, not in a sampled frame | open: a frame of more than 5 MiB of vertices is clamped by the GL ring. The Vulkan build does not log it. Raising the ring was not needed for the measured frames and was dropped |

## Open issues

1. The hologram and glow row pattern (EFB copy and blur chain) above is the main remaining render difference
   (29 to 41 dB). Next step: dump the converted copy (a debugging aid named `AURORA_GL_COPYDUMP` that was dropped
   with the removed wip series, so it has to be written again) at one hologram frame for Vulkan and GLES and compare source against destination.
2. The vertex ring overflow frame at startup needs a check that no visible draw is dropped (and a per frame growth or
   larger ring if it is).
3. Intro movie and save prompt were compared on the GPU only; on llvmpipe they were not repeated after the fix.
4. Only the 4:3 window at 640x480 was compared. Scenes after the match start (replay, results) are not covered.
