#!/bin/bash
# Deterministic offscreen run of the GPU build through menus into a match (virtual clock, frame exact scripted input from
# tests/compare/match.input), with the census on. Usage: tests/pc/gpu_match_run.sh <name> [exit frame, default 8300]
# Needs the test build (tests/compare/build_cmp.sh gles). Environment: extra AURORA_* variables pass through; BUILD overrides the build dir.
W="$(cd "$(dirname "$0")/../.." && pwd)"
N=$1; EXIT=${2:-8300}; O=$W/work/gpu-runs/$N; B=${BUILD:-${XTEST:-$W/work/xbuild-test}/build/gles-cmp}
rm -rf "$O" "$B/logs"; mkdir -p "$O/home" "$O/cap"
sed "s#^disc = .*#disc = $W/disc/R4QE01.rvz#" "$W/tests/compare/compare.ini" > "$O/mscharged.ini"
P=$((300 + RANDOM % 600))
Xvfb :$P -screen 0 1280x960x24 > "$O/xvfb.log" 2>&1 & X=$!
sleep 2
cd "$B"
env -u WAYLAND_DISPLAY DISPLAY=:$P SDL_VIDEODRIVER=x11 HOME="$O/home" SDL_AUDIODRIVER=dummy AURORA_CENSUS=${AURORA_CENSUS:-5} \
  CAPTURE_VTIME=1 CAPTURE_DIR="$O/cap" CAPTURE_FRAMES="" CAPTURE_EXIT_FRAME=$EXIT CAPTURE_INPUT="$W/tests/compare/match.input" \
  timeout -s KILL ${TIMEOUT:-1500} setarch "$(uname -m)" -R ./mscharged --config "$O/mscharged.ini" --disc "$W/disc/R4QE01.rvz" --window --size 640x480 > "$O/game.log" 2>&1
kill -9 $X 2>/dev/null
cp "$B/logs/mscharged.log" "$O/mscharged.log" 2>/dev/null
grep -E "gl-census" "$O/game.log" > "$O/census.txt"
tail -n 2 "$O/census.txt" | cut -c1-900
