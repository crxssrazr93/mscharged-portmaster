#!/bin/bash
# Offscreen run of the GLES build (upstream/build/gles-release) under Xvfb with Mesa, with screenshots.
# Nothing is shown on the desktop: Wayland is unset and the game uses a private X display.
# Usage: tests/pc/gles_boot.sh <out dir> [seconds, default 60]
# Host screenshots (key "p" in KEYS) are collected into <out dir>/host.
# Environment: INI (config file, default work/run-gles/mscharged.ini), EVERY (screenshot period, default 10),
#   KEYS ("<second>:<xdotool key> ...", e.g. "40:Return 50:x"), ARGS (extra mscharged arguments).
O=$(realpath -m "$1"); T=${2:-60}
W="$(cd "$(dirname "$0")/../.." && pwd)"
INI=${INI:-$W/work/run-gles/mscharged.ini}; EVERY=${EVERY:-10}
rm -rf "$O"; mkdir -p "$O/home"
N=$((300 + RANDOM % 600))
Xvfb :$N -screen 0 640x480x24 > "$O/xvfb.log" 2>&1 & X=$!
sleep 2
cd "$W/upstream/build/gles-release"
env -u WAYLAND_DISPLAY DISPLAY=:$N SDL_VIDEODRIVER=x11 HOME="$O/home" \
  ./mscharged --config "$INI" --disc "$W/disc/R4QE01.rvz" --window --size 576x432 $ARGS \
  > "$O/game.log" 2>&1 & G=$!
start=$SECONDS
( sleep 5; env -u WAYLAND_DISPLAY DISPLAY=:$N xdotool mousemove 300 200 ) &
for k in $KEYS; do
  ( sleep "${k%%:*}"; env -u WAYLAND_DISPLAY DISPLAY=:$N xdotool key "${k#*:}" ) &
done
for t in $(seq $EVERY $EVERY $T); do
  sleep $EVERY
  env -u WAYLAND_DISPLAY DISPLAY=:$N import -window root "$O/shot_$(printf %04d $t).png" 2>/dev/null
done
kill -TERM $G 2>/dev/null; sleep 3   # let the game flush its log, then make sure it is gone
kill -9 $G 2>/dev/null; kill -9 $X 2>/dev/null; wait 2>/dev/null
cp logs/mscharged.log "$O/mscharged.log" 2>/dev/null
mkdir -p "$O/host"; mv screenshots/*.png "$O/host/" 2>/dev/null
ls "$O"/shot_*.png | wc -l
