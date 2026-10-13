#!/bin/bash
# GPU work PC build: exports the patch series patches/aurora-gpu from the worktree work/aurora-gpu (branch gpu, on top of the
# committed GLES series and the aurora-pm series), assembles the series (GLES, pm, gpu), configures and builds work/xbuild-gpu/build/pc-gpu.
# Usage: [CMP=0] tools/gpu_pc_build.sh [ninja target, default mscharged]
# The PC build includes the virtual clock and the test capture hooks (inert unless CAPTURE_* is set); CMP=0 leaves them out.
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
TREE=$W/work/aurora-gpu; BASE=$(git -C "$TREE" rev-parse ":/aurora-pm series" 2>/dev/null || true)
BASE=$(git -C "$TREE" log --format=%H --grep='^aurora-pm series$' -n1)
OUTP=$W/patches/aurora-gpu
rm -rf "$OUTP"; mkdir -p "$OUTP"
git -C "$TREE" format-patch -q --no-signature --zero-commit -N -o "$OUTP" "$BASE..HEAD" > /dev/null
S=$W/work/xbuild-gpu-out/pc-series; rm -rf "$S"; mkdir -p "$S"
for p in $(cat "$W/patches/aurora-gles/series"); do git -C "$W" show "HEAD:patches/aurora-gles/$p" > "$S/$p"; echo "$p" >> "$S/series"; done
if [ "${GLESFIX:-1}" = 1 ]; then for p in "$W"/patches/aurora-glesfix/*.patch; do [ -e "$p" ] || continue; cp "$p" "$S/"; basename "$p" >> "$S/series"; done; fi
for p in "$W"/patches/aurora-pm/*.patch "$OUTP"/*.patch; do [ -e "$p" ] || continue; cp "$p" "$S/"; basename "$p" >> "$S/series"; done
CMPARGS=""
if [ "${CMP:-1}" = 1 ]; then
  cp "$W/work/gpu-vclock.patch" "$S/9999-virtual-clock.patch"; echo 9999-virtual-clock.patch >> "$S/series"; CMPARGS="-DMSCHARGED_TEST_CAPTURE=ON"
fi
cd "$W/work/xbuild-gpu"
B=build/pc-gpu
[ -f $B/CMakeCache.txt ] || cmake --preset gles-release -B $B $CMPARGS -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$S" > "$W/work/gpu-pc-configure.log" 2>&1 || { tail -30 "$W/work/gpu-pc-configure.log"; exit 1; }
cmake $CMPARGS $B > "$W/work/gpu-pc-reconfigure.log" 2>&1 || { tail -30 "$W/work/gpu-pc-reconfigure.log"; exit 1; }
cmake --build $B --target "${1:-mscharged}" -j8 -- -k 0 > "$W/work/gpu-pc-build.log" 2>&1 || true
grep -E 'error:|FAILED|undefined reference' "$W/work/gpu-pc-build.log" | cut -c1-250 | sort -u | head -${N:-40}
tail -1 "$W/work/gpu-pc-build.log"
