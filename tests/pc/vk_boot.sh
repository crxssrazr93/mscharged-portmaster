#!/bin/bash
# Offscreen boot of the Vulkan reference build (work/xbuild-test/build/release), screenshots every 15 s.
# Xvfb has no DRI3, so Vulkan cannot present there; a headless gamescope can, and shows nothing
# on the desktop. gamescopectl takes the screenshots (the X root window does not hold the
# Vulkan surface).
# Usage: tests/pc/vk_boot.sh <out dir> [seconds, default 60]
O=$1; T=${2:-60}; W="$(cd "$(dirname "$0")/../.." && pwd)"
rm -rf "$O"; mkdir -p "$O/home"
cat > "$O/inner.sh" <<IN
cd "${XTEST:-$W/work/xbuild-test}/build/release"
HOME="$O/home" XDG_CONFIG_HOME="$O/home/.config" XDG_DATA_HOME="$O/home/.local/share" SDL_VIDEODRIVER=x11 \
  ./mscharged --disc "$W/disc/R4QE01.rvz" --window --size 576x432 > "$O/game.log" 2>&1 & G=\$!
for t in \$(seq 15 15 $T); do sleep 15; gamescopectl screenshot "$O/shot_\$t.png" >/dev/null 2>&1; done
kill -9 \$G
IN
env -u WAYLAND_DISPLAY -u DISPLAY timeout -s KILL $((T + 40)) \
  gamescope --backend headless -W 640 -H 480 -w 640 -h 480 -- bash "$O/inner.sh" > "$O/gamescope.log" 2>&1
ls "$O"/shot_*.png
