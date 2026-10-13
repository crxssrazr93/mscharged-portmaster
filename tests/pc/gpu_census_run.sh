#!/bin/bash
# One offscreen scripted run of the GPU build with the census on (intro, menus, match).
# Usage: tests/pc/gpu_census_run.sh <name> [seconds, default 260]   Environment: extra AURORA_* variables pass through.
W="$(cd "$(dirname "$0")/../.." && pwd)"
N=$1; T=${2:-260}
export AURORA_CENSUS=${AURORA_CENSUS:-5}
rm -rf "$W/work/xbuild-gpu/build/pc-gpu/"{logs,*.db,*.loading}
BUILD=$W/work/xbuild-gpu/build/pc-gpu ACTIONS=$W/tests/pc/gles_match_actions.txt EVERY=20 \
  "$W/tests/pc/gles_boot.sh" "$W/work/gpu-runs/$N" "$T"
grep -E "gl-census" "$W/work/gpu-runs/$N/mscharged.log" > "$W/work/gpu-runs/$N/census.txt"
