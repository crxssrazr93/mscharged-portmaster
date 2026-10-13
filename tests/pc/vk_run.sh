#!/bin/bash
# Like vk_boot.sh but with the shared INI (skip intro etc.) and a configurable screenshot period.
# Usage: tests/pc/vk_run.sh <out dir> [seconds, default 60]   Environment: INI, EVERY (default 10)
O=$(realpath -m "$1"); T=${2:-60}; W="$(cd "$(dirname "$0")/../.." && pwd)"
INI=${INI:-$W/work/run-gles/mscharged.ini}; EVERY=${EVERY:-10}
rm -rf "$O"; mkdir -p "$O/home"
cat > "$O/inner.sh" <<IN
cd "${XTEST:-$W/work/xbuild-test}/build/release"
HOME="$O/home" XDG_CONFIG_HOME="$O/home/.config" XDG_DATA_HOME="$O/home/.local/share" SDL_VIDEODRIVER=x11 \
  ./mscharged --config "$INI" --disc "$W/disc/R4QE01.rvz" --window --size 576x432 > "$O/game.log" 2>&1 & G=\$!
for t in \$(seq $EVERY $EVERY $T); do sleep $EVERY; gamescopectl screenshot "$O/shot_\$(printf %04d \$t).png" >/dev/null 2>&1; done
kill -9 \$G
cp "$W/work/xbuild-test/build/release/logs/mscharged.log" "$O/mscharged.log"
IN
env -u WAYLAND_DISPLAY -u DISPLAY timeout -s KILL $((T + 40)) \
  gamescope --backend headless -W 640 -H 480 -w 640 -h 480 -- bash "$O/inner.sh" > "$O/gamescope.log" 2>&1
ls "$O"/shot_*.png | wc -l
