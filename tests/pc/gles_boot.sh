#!/bin/bash
# Offscreen boot of the GLES build (upstream/build/gles-release) under Xvfb with Mesa, screenshots every 15 s.
# Nothing is shown on the desktop: Wayland is unset and the game is pointed at a private X display.
# Usage: tests/pc/gles_boot.sh <out dir> [seconds, default 60] [extra mscharged args]
O=$(realpath -m "$1"); T=${2:-60}; shift 2 2>/dev/null
W="$(cd "$(dirname "$0")/../.." && pwd)"
rm -rf "$O"; mkdir -p "$O/home"
N=$((300 + RANDOM % 600))
Xvfb :$N -screen 0 640x480x24 > "$O/xvfb.log" 2>&1 & X=$!
sleep 2
cd "$W/upstream/build/gles-release"
env -u WAYLAND_DISPLAY DISPLAY=:$N SDL_VIDEODRIVER=x11 HOME="$O/home" XDG_CONFIG_HOME="$O/home/.config" \
  XDG_DATA_HOME="$O/home/.local/share" ./mscharged --config "$W/work/run-gles/mscharged.ini" --disc "$W/disc/R4QE01.rvz" --window --size 576x432 "$@" \
  > "$O/game.log" 2>&1 & G=$!
for t in $(seq 15 15 $T); do
  sleep 15
  env -u WAYLAND_DISPLAY DISPLAY=:$N import -window root "$O/shot_$t.png" 2>/dev/null
done
kill -9 $G 2>/dev/null; kill -9 $X 2>/dev/null
ls "$O"/shot_*.png
