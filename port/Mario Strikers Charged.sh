#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

GAMEDIR="/$directory/ports/mscharged"
BIN="$GAMEDIR/mscharged.aarch64"
cd "$GAMEDIR"

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Settings of this launcher (resolution, SDL backend, performance log): launch.cfg, see the README.
SDL_BACKEND=shim
RESOLUTION=native
ANTIALIASING=off
ASPECT=auto
PERF_LOG=0
MOVIE_ZOOM=0
[ -f "$GAMEDIR/launch.cfg" ] && source "$GAMEDIR/launch.cfg"

# The game disc: your own USA disc (R4QE01), as .rvz or .iso, in this folder or in game/.
DISC=""
for f in "$GAMEDIR"/R4QE01* "$GAMEDIR"/game/R4QE01* "$GAMEDIR"/*.rvz "$GAMEDIR"/*.RVZ "$GAMEDIR"/*.iso "$GAMEDIR"/*.ISO \
         "$GAMEDIR"/game/*.rvz "$GAMEDIR"/game/*.RVZ "$GAMEDIR"/game/*.iso "$GAMEDIR"/game/*.ISO; do
  case "${f,,}" in *.rvz|*.iso) [ -f "$f" ] && { DISC="$f"; break; } ;; esac
done
if [ -z "$DISC" ]; then
  pm_message "Game disc missing. Copy your Mario Strikers Charged USA disc (R4QE01.rvz or R4QE01.iso) into ports/mscharged/ (see the README)."
  sleep 8
  pm_finish
  exit 1
fi
echo "Disc: $DISC"

$ESUDO chmod +x "$BIN"

# Settings file: created from the defaults on the first run, then yours to edit.
[ -f "$GAMEDIR/mscharged.ini" ] || cp "$GAMEDIR/mscharged.ini.default" "$GAMEDIR/mscharged.ini"
set_ini() { sed -i "s/^$1 *=.*/$1 = $2/" "$GAMEDIR/mscharged.ini"; }
set_ini resolution "$RESOLUTION"
set_ini antialiasing "$ANTIALIASING"
set_ini aspect "$ASPECT"

# Screen size: PortMaster tells us; the game opens fullscreen at that size.
W="${DISPLAY_WIDTH:-640}"; H="${DISPLAY_HEIGHT:-480}"

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

if [ "$SDL_BACKEND" = "native" ]; then
  # SDL3 with its own KMSDRM and EGL/GLES driver (needs libdrm, libgbm and libEGL on the firmware).
  export LD_LIBRARY_PATH="$GAMEDIR/libs.native${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export SDL_VIDEODRIVER=kmsdrm
else
  # SDL3 shim that runs on the firmware's own SDL2 (which already works with the display and the GPU driver).
  export LD_LIBRARY_PATH="$GAMEDIR/libs.aarch64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export SDL3SHIM_SDL2_LIB="${SDL3SHIM_SDL2_LIB:-libSDL2-2.0.so.0}"
  unset SDL_VIDEODRIVER
fi

# Performance log: one "[perf]" line per second (fps and frame times) in log.txt.
[ "$PERF_LOG" = "1" ] && export MSCHARGED_PERF_LOG=1
export MSCHARGED_PERF_LOG="${MSCHARGED_PERF_LOG:-0}"

# Movies on a 4:3 screen: the game shows its 16:9 movies in a box with bars above and below. MOVIE_ZOOM=1 fills the
# screen height instead (the sides are cropped).
[ "$MOVIE_ZOOM" = "1" ] && export MSCHARGED_MOVIE_ZOOM=1

# Exit hotkey only (Select + Start); the game reads the controller directly.
$GPTOKEYB "mscharged.aarch64" -c "$GAMEDIR/mscharged.gptk" &
pm_platform_helper "$BIN"

ARGS=(--config "$GAMEDIR/mscharged.ini" --disc "$DISC" --fullscreen --size "${W}x${H}")
"$BIN" "${ARGS[@]}"

pm_finish
