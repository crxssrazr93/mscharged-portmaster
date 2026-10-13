#!/bin/bash
# One offscreen scripted run of the PC GLES build with the texture census on (intro, menus, match).
# Usage: tests/pc/gpu_census_run.sh <name> [seconds, default 260]
# Environment: BUILD (build dir, default work/xbuild-src/build/pc-gles), extra AURORA_* variables pass through,
#   RSS_AT (see gles_boot.sh).
W="$(cd "$(dirname "$0")/../.." && pwd)"
N=$1; T=${2:-260}
export AURORA_CENSUS=${AURORA_CENSUS:-5}
B=${BUILD:-$W/work/xbuild-src/build/pc-gles}
rm -rf "$B"/{logs,*.db,*.loading}
BUILD=$B ACTIONS=$W/tests/pc/gles_match_actions.txt EVERY=20 \
  "$W/tests/pc/gles_boot.sh" "$W/work/gpu-runs/$N" "$T"
grep -E "gl-census" "$W/work/gpu-runs/$N/mscharged.log" > "$W/work/gpu-runs/$N/census.txt"
tail -n 3 "$W/work/gpu-runs/$N/census.txt" | cut -c1-600
