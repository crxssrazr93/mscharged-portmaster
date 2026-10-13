#!/bin/bash
# Native x86 build of the same sources (work/xbuild-src/build/pc-perf) for counter runs and reference checks.
# The Aurora series is the committed GLES series (git HEAD, unaffected by edits another agent is making) plus
# patches/aurora-pm. Usage: build/21_pc_build.sh [extra cmake args, e.g. -DMSCHARGED_AX_REFERENCE_CHECK=ON]
set -euo pipefail
source "$(dirname "$0")/common.sh"
SERIES="$W/work/cpu-series"; rm -rf "$SERIES"; mkdir -p "$SERIES"
git -C "$W" archive HEAD patches/aurora-gles | tar -x -C "$SERIES" --strip-components=2
cp "$W"/patches/aurora-pm/*.patch "$SERIES/"
for p in "$W"/patches/aurora-pm/*.patch; do basename "$p" >> "$SERIES/series"; done
cd "$SRC"
cmake -S . -B build/pc-perf -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$SERIES" "$@" > "$W/work/pc-cpu-configure.log" 2>&1
cmake --build build/pc-perf --target mscharged -j"${JOBS:-6}" > "$W/work/pc-cpu-build.log" 2>&1
tail -3 "$W/work/pc-cpu-build.log"
