#!/bin/bash
# One deterministic capture run, fully offscreen.
# Usage: tests/compare/run.sh <gles|glesgpu|vk> <out dir> <frames list> [exit frame]
# Environment: INPUT (script file), SIZE (default 640x480), INI (default tests/compare/compare.ini),
#   TAG (runs ./mscharged$TAG, see build_cmp.sh), TRACE=1 (per frame virtual time/retrace trace), TIMEOUT (seconds, default 3000), ASPECT (4:3|16:9).
# GLES runs under Xvfb (Mesa). Vulkan cannot present on Xvfb, so it runs in a headless gamescope.
# Prints the game's PID file path; kills everything it started.
set -u
KIND=$1; O=$(realpath -m "$2"); FR=$3; EXIT=${4:-}
W="$(cd "$(dirname "$0")/../.." && pwd)"
SIZE=${SIZE:-640x480}; INI=${INI:-$W/tests/compare/compare.ini}; TIMEOUT=${TIMEOUT:-3000}
rm -rf "$O"; mkdir -p "$O/home" "$O/cap"
BIN_DIR=$W/upstream/build/$([ "$KIND" = vk ] && echo vk-cmp || echo gles-cmp)
# KIND glesgpu: the GLES build on the Intel GPU (Mesa iris) inside the same headless gamescope as Vulkan.
[ -n "${INPUT:-}" ] && INPUT=$(readlink -f "$INPUT")
CFG="$O/mscharged.ini"; sed "s#^width = .*#width = ${SIZE%x*}#; s#^height = .*#height = ${SIZE#*x}#" "$INI" > "$CFG"
[ -n "${ASPECT:-}" ] && sed -i "s#^aspect = .*#aspect = $ASPECT#" "$CFG"
cat > "$O/inner.sh" <<IN
cd "$BIN_DIR"
export HOME="$O/home" XDG_CONFIG_HOME="$O/home/.config" XDG_DATA_HOME="$O/home/.local/share" SDL_AUDIODRIVER=dummy
export CAPTURE_VTIME=1 CAPTURE_DIR="$O/cap" CAPTURE_FRAMES="$FR" CAPTURE_EXIT_FRAME="$EXIT" ${DUMP:+CAPTURE_DUMP="$DUMP"} ${TRACE:+CAPTURE_TRACE=$TRACE} ${INPUT:+CAPTURE_INPUT="$INPUT"}
export AURORA_GL_DEBUG=\${AURORA_GL_DEBUG:-}
exec setarch \$(uname -m) -R ./mscharged${TAG:-} --config "$CFG" --disc "$W/disc/R4QE01.rvz" --window --size $SIZE > "$O/game.log" 2>&1
IN
chmod +x "$O/inner.sh"
if [ "$KIND" = vk ] || [ "$KIND" = glesgpu ]; then
  env -u WAYLAND_DISPLAY -u DISPLAY timeout -s KILL "$TIMEOUT" gamescope --backend headless -W 1920 -H 1080 -w 1920 -h 1080 -- bash "$O/inner.sh" > "$O/gamescope.log" 2>&1
else
  N=$((300 + RANDOM % 600))
  Xvfb :$N -screen 0 1920x1080x24 > "$O/xvfb.log" 2>&1 & X=$!
  sleep 2
  env -u WAYLAND_DISPLAY DISPLAY=:$N SDL_VIDEODRIVER=x11 timeout -s KILL "$TIMEOUT" bash "$O/inner.sh"
  kill -9 $X 2>/dev/null
fi
cp "$BIN_DIR/logs/mscharged.log" "$O/mscharged.log" 2>/dev/null
ls "$O/cap" | wc -l
