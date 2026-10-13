## Notes

Mario Strikers Charged runs here as a native Linux port. The game code comes from the community decompilation of the Wii game, wrapped by the mscharged port, and drawn through an OpenGL ES 3 renderer so that it can run on handheld GPUs such as the Mali G31 of the Allwinner H700.

This port is experimental. Expect performance work to continue.

## Installation

The port does not contain the game. You need your own Mario Strikers Charged disc, the USA release (game ID R4QE01, revision 1).

1. Dump your disc to an .rvz or .iso file.
2. Copy that file into `ports/mscharged/` (a `game` folder inside it also works).
3. Start Mario Strikers Charged from the Ports menu.

The launcher looks for a file named R4QE01 first, then for any .rvz or .iso file. If nothing is found it shows a message and exits. The disc image is read directly, nothing is extracted or converted. Saves and caches are written to `ports/mscharged/original-main-credits-data/`.

## Controls

The game is played with the controller as a Wii Remote with Nunchuk. The left stick is the Nunchuk stick, the right stick moves the pointer in menus.

| Controller button | Wii input | What it does in the game |
| --- | --- | --- |
| Left stick | Nunchuk stick | Move the player |
| Right stick | Pointer | Aim and point in menus |
| D-pad | D-pad | Menu navigation |
| Bottom face button | A | Confirm in menus, pass |
| Right face button | B | Back in menus, shoot |
| Left face button | 1 | Pause and resume in a match |
| Top face button | 2 | Second action button |
| Start | Plus and 1 | Pause and resume in a match, Press Plus on the title screen |
| Select | Minus | Title screen and the page tabs of the Controls page (unused in a match, as on the Wii) |
| Menu or Guide | Home | Skips fades and movies |
| L1 | C | Nunchuk C (chip shot) |
| L2 | Z | Nunchuk Z (aim) |
| R1 | Shake Nunchuk | Switch items |
| R2 | Shake Remote | Hit an opponent |
| Select and Start together | none | Quit the port |

Buttons are named by position. On the RG35XX H the printed labels follow the Nintendo layout, so its B button (bottom) passes and its A button (right) shoots; its Y (left) is the Wii 1 and its X (top) is the Wii 2. Players who prefer other buttons can make a profile in `mscharged.ini`.

Hold Select and press Start to quit.

## Settings

The launcher settings are in `ports/mscharged/launch.cfg`. Remove the leading # of a line to change it.

| Setting | Values | Meaning |
| --- | --- | --- |
| RESOLUTION | native, 2x, 3x, 4x, window | Size of the 3D picture. native is the Wii's own 640x448 and the fastest, it is the default. window draws at the full screen size. |
| ANTIALIASING | off, 4x | Edge smoothing of the 3D picture. off is the default. |
| ASPECT | auto, 4:3, 16:9 | Game layout. auto follows the shape of the screen. |
| PERF_LOG | 0, 1 | With 1 the game prints one line per second with the frames per second and the frame times into `ports/mscharged/log.txt`. |
| MOVIE_ZOOM | 0, 1 | On a 4:3 screen the game shows its widescreen movies in a box with bars above and below. With 1 the movie fills the screen height and the sides are cropped. 0 (default) keeps the original look. |
| SDL_BACKEND | shim, native | How SDL3 reaches the screen, see below. |

More settings (volume, controller layouts, optional game tweaks such as skipping the intro) are in `ports/mscharged/mscharged.ini`, which is created on the first start. Delete it to get the defaults back. RESOLUTION, ANTIALIASING and ASPECT from `launch.cfg` are applied on every start and replace the same keys in the INI file.

The performance log lines look like this:

```
[perf] fps=29.8 frame_ms_avg=33.55 frame_ms_max=41.20 game_ms_avg=21.04 presents_per_s=29.8 vi_per_s=59.6 frames=1790
```

frame_ms_avg is the time between two game frames, game_ms_avg the part of it spent inside the game frame itself. The Wii game runs at 60 field updates per second (vi_per_s) and shows a new picture about 30 times per second when it keeps up.

## SDL backend

The game uses SDL3, which firmwares do not ship. The port bundles an SDL3 that runs on top of the SDL2 of your firmware (the shim, default). Window, audio and controllers then work exactly as they do for every SDL2 port on that device, including devices with vendor GPU drivers. If a firmware has no usable SDL2, set SDL_BACKEND=native in `launch.cfg` to use a bundled SDL3 that opens the screen itself through KMSDRM, which needs libdrm, libgbm and libEGL on the firmware (normally present with Mesa Panfrost).

## Troubleshooting

Everything the game prints goes to `ports/mscharged/log.txt`. The game's own log is in `ports/mscharged/logs/mscharged.log`.

## Credits

* Yannick Suter for the mscharged port and the mscharged-decomp decompilation project.
* The Aurora project (Luke Street and contributors) for the GameCube and Wii compatibility layer, and bmdhacks for the OpenGL ES backend work and the SDL3 on SDL2 shim used for handhelds.
* Next Level Games and Nintendo for the original game.

Mario Strikers Charged is a trademark of Nintendo. This port contains no game data.
