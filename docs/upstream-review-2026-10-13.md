# Upstream review, 2026-10-13

Scope: everything newer than our current base. Nothing was rebased or built. The scratch trees from the aborted rebase attempt (`work/xbuild-up`, `work/aurora-up`) were deleted, and no `patches-next/` was created.

Current base: yannicksuter/mscharged-port `d7cdfc47` (1.0.7). Target: `origin/main` `64dcb73b` (1.0.8), 27 commits (listed below). Verdict codes: (a) helps a problem we have, (b) neutral or needed to stay in sync, (c) irrelevant on a handheld, (d) conflicts with one of our patches.

## Pins

* Aurora pin in the port: unchanged, still `d664382` (`extern/aurora`). The port instead gained its own patch `patches/aurora/0089` (series now 0001 to 0089).
* Decomp pin in the port: unchanged, still `7a6bf165`. The decomp series gained `0690` (temporary), the tweaks series gained `0006` and `0007` and changed `0003` and `0005`.
* The merge commit `fd254636` (PR 16) only brings the first parent's diff; its tweaks series files (0001 to 0004) and `0088` are already in our base.

## Dry run result (done before the stop order, then discarded)

All port series applied to `origin/main` without conflict: `port-gles`, `port-pm` (both), `port-perf`. The Aurora series `aurora-gles`, `aurora-glesfix`, `aurora-pm` and `aurora-gpu` 0001 to 0006 applied on top of `0001..0089` with `git apply` and no textual conflict, including `lib/gfx/texture_convert.cpp`, `lib/gfx/texture.cpp` and `lib/gx/texture.cpp`. This was not compiled, so a semantic check is still open (see Aurora patch 0089 below). The only real collision is a name and number clash in the decomp series (`0690`).

## mscharged-port commits (d7cdfc47..origin/main)

### Performance and memory

| Commit | What it does | Verdict |
|---|---|---|
| `79533e78` perf(aurora) authored mipmap check | New Aurora patch 0089. `arb_mip_check` in `texture_convert.cpp` downscales with packed 64 bit lanes and sums squared differences in 4096 byte blocks (vectorizable), and exits early once the average exceeds the threshold. Bit identical result. | (a) CPU cost on every texture upload, hot on a Cortex A53 during loads. Touches `texture_convert.cpp`, which our `aurora-gles` 0004 and `aurora-gpu` edit elsewhere in the file (the `to_gl` return lines near line 622 to 770); the hunks do not overlap. Needs a compile check: GLES `ConvertedTexture`/`ByteBuffer` types are shared with the code 0089 uses. |
| `59f06931` perf(platform) stack limits once on Linux | `CurrentThreadStackLimits` caches per thread. glibc parses `/proc/self/maps` on every main thread call, and the tweak registry asks for each tweak name; a match load made a 99 ms game thread frame, now 36 ms. | (a) Strong. The registry runs whenever `MSCHARGED_TWEAKS` is compiled in, even with all tweaks off, and /proc parsing is slower on the device. Clean, `src/platform/thread.cpp` is not in any of our patches. |
| `d21fe7ac` perf(frontend) FEN storage out of the game heap | The FEN transport's containers and native image use the host metadata allocator instead of the game's address ordered free list. 11k to 39k allocations per menu scene took 50 to 550 ms and stalled audio. | (a) Menu scene changes, audio stalls, and heap fragmentation. Output byte identical. No overlap with our patches (`frontend_package.*`, `OriginalFrontend.cmake`). |
| `fd524a99` perf(frontend) describe each FEN record layout once | Refactor of `frontend_package.cpp` that removes repeated layout code; same converted bytes. | (a) Part of the same menu speed work, small CPU saving. |
| `babbe6bd` test(host) FEN transport tests | Host tests for the two commits above. | (b) Tests only. |

### Rendering fixes (decomp tweaks series, always on, apply only if `MSCHARGED_TWEAKS` is defined in the module, which it is for the frontend module)

| Commit | What it does | Verdict |
|---|---|---|
| `0e024d18` fix(render) goal nets (#19) | `DrawableNetMesh::Render` rebuilds a resting net every frame so a replay's bulged shape is not left on screen. | (a) Rendering bug fix. Costs a small amount of CPU per frame for two net meshes; check it on the A53 profile. Affects the decomp tweaks series, not our patches. |
| `19c1cb24` fix(render) shell shadow height (#18) | Lifts the flying shells' ground shadow. | (a) Rendering bug fix, tiny. |

### Tweaks and gameplay

| Commit | What it does | Verdict |
|---|---|---|
| `d6132ad5`, `f4b3cf9e`, `64dcb73b` Fast menus (#26) | Popup black box opens at once; transitions after a match are skipped. Edits tweak 0005. Docs commit changes `game_tweaks.h` text. | (b) Optional user setting, can shorten menu waits on a slow device. |
| `d8369b47`, `86cbfdb2` No Mega Strikes spares only Strikers 101 (#22) | Tweak 0003 narrowed; docs and ini text. | (c) Gameplay option only. |
| `caf2f087` fix(ai) missing sidekicks (#25) | Decomp patch 0690, temporary: tests AI desire update result as the 32 bit code. The decomp has the same fix at `e4d2dac8`, so the patch goes when the pin moves. | (d) Name clash: our `patches/decomp-pm/0690-aarch64-wprintf-va-list.patch` has the same number. Different file names, but the port's `series` order and the "apply after 0689" note in our patch need to be updated: renumber ours to 0691 and 0692 (movie zoom). Our two patches touch `src/MSL/wprintf.c` and `src/Game/FE/feRender.cpp`, neither touched by 0690. Also an AArch64 correctness item: the unwritten 4 bytes behavior is a 64 bit issue (a) on the device as well. |

### Input, Wii Remote, launcher, saves

| Commit | What it does | Verdict |
|---|---|---|
| `8f412465`, `fac2a325`, `155ffbe2`, `b5d055e1`, `cab54969` | Wii Remotes over Bluetooth (HID, Windows scan and connect), removal of pointer calibration. Changes `hardware_owner`, `wiimote_*`, `config`, and `original_main_credits.cpp` (remote map keyed by device id). | (c) Not usable on handhelds. They do change shared files: `hardware_owner.cpp` and `original_main_credits.cpp`. No conflict with `port-pm` 0001/0002 or `port-perf`. These add compiled code to the aarch64 build (`charged_wiimote_scan` gains `wiimote_ir.cpp`, `wiimote_bluetooth.cpp`); the build should still pass but must be checked once with the cross toolchain. |
| `47cbd926` docs readme, `31331bf4` version 1.0.8, `982c9706` merge | Docs, version bump. | (b) The version bump is a one line `CMakeLists.txt` hunk next to our `port-gles` edits. It applied cleanly. |
| `eb0564a3` saves in a chosen folder, `13696d6e` import Dolphin saves | New `[saves]` folder setting (`ResolveSaveFolder`) and `save_import.cpp`. `original_main_credits.cpp` now takes the NAND folder from the setting. | (b) Needs to stay in sync. Potentially useful on device: saves can be moved off the SD game folder with one ini key. |
| `12efead5`, `8632559b`, `a0dcab62` launcher | Launcher UI changes. | (c) |

### Other

None of the 27 commits touches `src/runtime/frame_aurora.cpp`, `gpu_readback.cpp`, `gx_check.cpp`, `scene.cpp`, `graphics_backend.h` or the graphics cmake (`GraphicsCheck.cmake`, `GraphicsProviders.cmake`, `AuroraHost.cmake`) in a way that overlaps our `port-gles` hunks.

## mscharged-decomp (not pinned: pin stays 7a6bf165)

16 commits newer on origin/main (about 336 files). The port does not take them until it moves its pin. They matter for us only when it does.

| Commit | What it does | Verdict |
|---|---|---|
| `e4d2dac8` desire update results as 32 bit codes | Same fix as port patch 0690. | (b) Port will drop its 0690 when the pin includes this. We then drop our renumber. |
| `d5bc740c` match revision 1 movie playback | `MovieStart` signature split by `VERSION_R4QP01_REV1` in `Game/Sys/movie.cpp`, `SHMoviePlayer.cpp`, `SHStadiumSelect.cpp`. | (c) Revision 1 PAL only. Our `0691-movie-zoom-option` touches `feRender.cpp` only. |
| `126acd42`, `22c9ec16`, `6cd51cdf`, `1002451c`, `7854035d`, `153f02a8`, `5b4e6845`, `93df0d44`, `e3dc6f32`, `cc38c4ed`, `43f5731f`, `4fa4768a`, `8cfdd92a`, `eeed4ff2` | European revision 1 and 2 support (disc messages, KPAD, WPAD encryption, DWC, Mii filter, audio effects, pause menu). Also source clean ups in `src/MSL`, `src/ode`, `src/Runtime`. | (c) EU only, the USA R4QE01 build is documented as byte identical. A diff in `src/MSL/wprintf.c` (3 lines) is the nearest to our patch: it is a small change and may collide with our `0690-aarch64-wprintf-va-list.patch` hunk when the pin moves. Check then. |

## encounter/aurora (newer than d664382)

| Commit | What it does | Verdict |
|---|---|---|
| `c8406f2` Stop overwriting DVD userData | DVD layer fix. | (b) Neutral. |
| `6f07a59` Add `aurora::gfx::readback` API | New EFB point and copy readback API (`lib/gfx/readback/*`, `depth_peek` removed, `GXAurora.h` docs), touching `recording.cpp`, `frame.cpp`, `encoding.cpp`, `tex_copy_conv.cpp`, `GXCpu2Efb.cpp`. 40+ files. | (d) Heavy conflict with `aurora-gles` (0003 recording and 0004 translation replace the Dawn side of all those files) and `aurora-gpu`. It also needs a GL implementation of the readback. Do not adopt now. Only the port's own use (it may later call the new API) would force it. |
| `5179721` `AuroraSetDrawsBlocking` | Sub command `GX_AURORA_SET_DRAWS_BLOCKING` and a `blocking` parameter on `find_pipeline`: draws either wait for pipeline compile or are skipped. Default is async (skip). | (a) Relevant to shader stalls: it is the same idea as our bounded, non fatal pipeline waits in `aurora-gpu` 0005. (d) Touches `pipeline_cache.*`, `recording.cpp`, `command_processor.cpp`, `gx.hpp`, all rewritten by our GLES series. Adopt only if the port starts calling it. |

The port pins `d664382` and neither commit is in any port patch, so neither is needed to build. Do not move the Aurora pin unless the port does.

## bmdhacks/aurora

Newest branch is `main` (2026-09-02, "Support Bullseye's C++20 library subset") and `gles-backend` (2026-07-18). Nothing newer than what the port tracked. Worth a one time diff against our `aurora-gles`, because `gles-backend` ends with commits for the 1 GB G31 OOM: `415ba8d` (two GPU object leaks: `~TextureRef` deleting its GL texture and a sampler cache that never hit because of padding bytes in the hash), `bda2188` (persistent program binary cache), `fe72c84` (dedupe identical GX programs), `3c60339` (persistently mapped ring buffers) and `f6d202b` (stop freeing the per frame ByteBuffer pool). We already carry `~TextureRef` and the sampler hash (`aurora-gpu` 0001 and `aurora-gles`), and a bincache (`aurora-gpu` 0005). The others should be compared, not assumed.

## Recommendation

Adopt (in this order):

1. Rebase the whole base to `origin/main` (1.0.8). The commits that help us (`59f06931`, `d21fe7ac`, `fd524a99`, `79533e78`, and the two render fixes) arrive with it, and there is no sensible way to take them alone; everything else is neutral or ignorable.
2. Port series: `port-gles`, `port-pm`, `port-perf` apply as they are. Rebuild and boot the PC GLES binary and the aarch64 cross build, since the Wii Remote and save import code adds new sources to the cross build.
3. Decomp series: renumber `decomp-pm` to 0691 and 0692, update the note "apply after 0689" to "after 0690", and update `build/01_fetch.sh` (`PORT_COMMIT=64dcb73b`; it also installs the decomp patches into `patches/mscharged-decomp/series`). Drop the renumber later when the pin includes `e4d2dac8`; re check `wprintf.c` then.
4. Aurora series order: upstream `0001..0089`, then `aurora-gles`, `aurora-glesfix`, `aurora-pm`, `aurora-gpu`, then `test-capture`. `patches/aurora-gles/base` and the `base` files for `test-capture` stay at `d664382`. Compile check 0089 against the GL texture types and run a texture upload comparison; if our texture compaction (`texture_compact.cpp`) wants the same `arb_mip_check` result, the early exit is a pure speed change and cannot alter it.
5. Verify with the THP census (`AURORA_CENSUS=5`) that texture count still plateaus, then build `dist/mscharged-next.zip`.

Skip for now: the Aurora readback API (`6f07a59`) and `AuroraSetDrawsBlocking` (`5179721`), because they conflict heavily with the GLES backend and need GL work, and the Aurora pin should only move together with the port.

Expected conflicts when we do it, in order of likelihood:

* Decomp patch number clash `0690` (renaming fixes it).
* `lib/gfx/texture_convert.cpp` (0089 against `aurora-gles` 0004 and `aurora-gpu` 0001): none textually in the dry run, possible semantic issues at compile time.
* `cmake/AuroraHost.cmake`, `CMakeLists.txt` and `CMakePresets.json` as upstream edits them (version, `save_import.cpp`); applied cleanly in the dry run, so only expect trouble if upstream changes them again before the rebase.
* Patches the other agents are editing right now (`aurora-gpu` 0007 and 0008, `port-perf`, `port-input`) need to be committed first. Rebase against the committed state only.
