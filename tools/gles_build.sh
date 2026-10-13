#!/bin/bash
# PC build of the GLES port from the prepared tree (build/01_fetch.sh creates work/xbuild-src: the port at the pinned
# commit with patches/port-gles, port-pm, port-perf and the decomp patches). The Aurora series is assembled by
# tools/aurora_series.sh (gles, glesfix, pm, gpu). The build directory is work/xbuild-src/build/pc-gles.
# Usage: tools/gles_build.sh [target, default mscharged]
# PRESET=gles-handheld builds the lean handheld game (MSCHARGED_HANDHELD=ON, patches/aurora-handheld) in build/pc-handheld.
# Environment: XSRC (other prepared tree), BDIR (build dir name, default pc-gles), CMAKE_ARGS (extra cmake arguments,
#   e.g. -DMSCHARGED_HANDHELD=OFF), GLESFIX/AURORA_PM/AURORA_GPU=0 (skip a series), N (error lines to print).
set -e
W="$(cd "$(dirname "$0")/.." && pwd)"
PRESET=${PRESET:-gles-release}; [ "$PRESET" = gles-handheld ] && { export HANDHELD=1; BDIR=${BDIR:-pc-handheld}; }
SRC="${XSRC:-$W/work/xbuild-src}"; B=build/${BDIR:-pc-gles}
S=$W/work/aurora-series-pc; "$W/tools/aurora_series.sh" "$S"
cd "$SRC"
cmake --preset "$PRESET" -B "$B" -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$S" -DBUILD_TESTING=OFF $CMAKE_ARGS > "$W/work/gles-configure.log" 2>&1 || { tail -30 "$W/work/gles-configure.log"; exit 1; }
cmake --build "$B" --target "${1:-mscharged}" -j8 -- -k 0 > "$W/work/gles-build.log" 2>&1 || true
grep -E 'error:|FAILED|undefined reference' "$W/work/gles-build.log" | cut -c1-250 | sort | uniq | head -${N:-40}
tail -1 "$W/work/gles-build.log"
