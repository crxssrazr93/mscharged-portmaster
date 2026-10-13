# Rebase and handheld strip, 2026-10-13

Base moved from yannicksuter/mscharged-port `d7cdfc47` (1.0.7) to `64dcb73b` (1.0.8) as a whole, pins unchanged (Aurora `d664382`, decomp `7a6bf165`). The old base stays reproducible with the git tag `base-d7cdfc47`. The plan followed `docs/upstream-review-2026-10-13.md`.

## Rebase

| Item | Result |
|---|---|
| Port series (`port-gles`, `port-pm`, `port-perf`) | Applied without conflict |
| Decomp series | Only collision: the port's new temporary `0690`. `decomp-pm` renumbered to `0691` (aarch64 wprintf va_list) and `0692` (movie zoom), the "apply after" notes updated |
| Aurora series | Upstream 0001 to 0089, then `aurora-gles`, `aurora-glesfix`, `aurora-pm`, `aurora-gpu` (0001 to 0006), no textual conflict. Upstream 0089 (faster authored mipmap check) compiled against the GL texture types without changes |
| Test capture | The port test patch applies to the rebased tree but not after the handheld patch (same `CMakeLists.txt` area), so the test build uses its own tree (`TEST_CAPTURE=1 build/01_fetch.sh`) |
| Scripts | `01_fetch.sh` fetched only `main` at clone time and `RESET=1` reset after the checkout (both fixed), `aurora_series.sh` now assembles all four series, PC build from the prepared tree instead of `./upstream` |

Boot and census on the PC GLES build (Xvfb, Mesa, one game, killed by PID, nothing left running):

* Boots to the main menu and through the scripted menu actions (`tests/pc/gles_match_actions.txt`) into a match on the pitch (0 to 0, timer running), for the rebased full build and for the handheld build.
* THP census (`AURORA_CENSUS=3`, intro movies, intro not skipped): the texture count is flat at 40 to 41 from second 30 to second 115 (the whole intro and attract movie phase), 14 MB. No growth. In the scripted run to a match the count follows the scenes (76 in the menus, 428 in the match, 57 MB, plateauing inside each scene).

## Handheld strip

`MSCHARGED_HANDHELD=ON` (preset `gles-handheld`, `build/20_build.sh` default). Patches: `patches/port-handheld`, `patches/aurora-handheld` (Aurora option `AURORA_LEAN`). The PC GLES and Vulkan presets are unchanged (the option is off there and needs the GLES backend). Checked: GLES PC build with launcher compiles and links with the handheld patch applied, Vulkan preset (`release`) configures.

### Sizes (aarch64, stripped, as shipped)

| File | Before | After | Change |
|---|---|---|---|
| `mscharged.aarch64` | 9,603,024 | 6,783,496 | minus 2,819,528 (29.4 percent) |
| `.text` of it | 6,354,936 | 4,543,288 | minus 1,811,648 |
| frontend module | 4,328,480 | 4,328,384 | same |
| main credits module | 399,672 | 399,648 | same |
| `dist/mscharged.zip` | 9,016,912 | 7,437,724 | minus 1,579,188 (17.5 percent) |

PC (x86, SDL3 linked in statically): 15.3 MB stripped before, 12.4 MB handheld (15.6 MB for the rebased full build).

### Memory at the main menu (PC, Xvfb, VmRSS median over seconds 24 to 34 of the scripted run, single runs)

| Build | RSS |
|---|---|
| old base `d7cdfc47`, GLES | 622 MB |
| 1.0.8 rebased, full (launcher built in) | 610 MB |
| 1.0.8 handheld | 587 MB (two runs, 587 and 587) |

The gain is code and static data only (about 35 MB less than the old base, 23 MB less than the rebased full build). Textures and game memory do not change.

### What was stripped, with size (PC link map, input section bytes; the aarch64 binary dropped by the same order, 2.8 MB)

| Removed | Size |
|---|---|
| Dear ImGui (Aurora overlay and launcher) and its backends | 939 KB and 25 KB |
| FreeType (ImGui text) | 843 KB |
| Window icon (embedded PNG and decoder glue) | 364 KB |
| libpng and zlib (PNG screenshots, launcher images) | 244 KB |
| Launcher UI (`src/launcher/main.cpp`, `ui_kit.cpp`), replaced by a 50 line entry point | 256 KB |
| Wii Remote scan, DolphinBar, Bluetooth helpers | 82 KB |
| Wii Remote HID driver (an empty driver with the same interface takes its place) | 72 KB |
| Config host library parts (Dolphin save import) | 64 KB |
| SQLite features Aurora never calls (`SQLITE_OMIT_*`) | 52 KB (65 KB in the aarch64 binary) |

Also not built any more: `mscharged-bootstrap`, `mscharged-gx-check`, `mscharged-original-main-credits-check`, `session_log_tests`, all unit tests, the imgui, freetype, libpng and zlib providers (not even prepared). The shipped default `mscharged.ini.default` lost the DolphinBar calibration keys and the `[launcher]` section.

Compiled with `-ffunction-sections -fdata-sections` and `--gc-sections` for everything (the executable already used `--gc-sections`), which lets the linker drop unreferenced functions of the whole archive Aurora libraries.

### Kept on purpose

| Kept | Why |
|---|---|
| Keyboard and gamepad bindings, `desktop_wpad`, `wpad_sdl` | The handheld controls (gamepad as Wii Remote with Nunchuk) |
| SQLite and zstd | Shader and pipeline cache (WAL database), needed for stutter free loads |
| nod | Reads the disc image (rvz and iso) |
| `session_log` | `logs/mscharged.log` and the crash report |
| Texture replacement hooks of Aurora | Already a 42 line stub in `aurora-gles` (every lookup says no). The calls sit in the texture upload path and removing them changes hashing code for no measurable gain |
| Tracy | Compiled out already (`TRACY_ENABLE=OFF`), contributes nothing |
| The one time XFB snapshot of the runtime loop | Coupled to the frame loop of the diagnostic driver (about 860 KB written once), left alone to keep the loop identical |
| Wii Remote strings in the input owner and config parser | A few hundred bytes of text, the config format stays compatible |

Already absent before this work: Dawn and WebGPU (the GLES series 0001 removes them, `aurora::webgpu` is only a namespace name of the GL layer), Qt and RmlUi (never fetched or built for the GLES backend), Windows and macOS only sources (never compiled on Linux).

### Link time optimization

`MSCHARGED_HANDHELD_LTO=ON` (`LTO=1 build/20_build.sh`, own build directory) works after four changes: llvm archive tools in the toolchain, the game modules and everything they link stay non LTO (the decomp mixes 16 and 32 bit `wchar_t`, which a single LTO module cannot merge, and object libraries enter the modules as object sources), and Tracy must not see the global IPO switch (it then embeds its objects in every consumer and the whole archive link reports duplicates). Result: the ThinLTO executable is 6,849,040 bytes, 65,544 bytes larger than the normal one (6,783,496), and the speed on a Cortex A53 cannot be measured without the device. Not adopted, the option stays off; `dist/mscharged.zip` is the normal build.
