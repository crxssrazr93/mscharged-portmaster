#!/bin/bash
# Re-export the Aurora GLES patches from the worktree, re-prepare sources and build the GLES port.
# Usage: tools/gles_build.sh [target, default mscharged]
set -e
W="$(cd "$(dirname "$0")/.." && pwd)"
# The committed patches/aurora-gles is authoritative (the dev worktree also holds unmerged wip commits that would
# conflict with patches/aurora-glesfix); re-export it explicitly with GLES_EXPORT=1.
[ "${GLES_EXPORT:-0}" = 1 ] && "$W/tools/export_aurora_gles.sh" > /dev/null
cd "$W/upstream"
"$W/tools/aurora_series.sh" "$W/work/aurora-series-gles"   # patches/aurora-gles + patches/aurora-glesfix
cmake --preset gles-release -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$W/work/aurora-series-gles" > "$W/work/gles-configure.log" 2>&1 || { tail -30 "$W/work/gles-configure.log"; exit 1; }
cmake --build build/gles-release --target "${1:-mscharged}" -j8 -- -k 0 > "$W/work/gles-build.log" 2>&1 || true
grep -E 'error:|FAILED|undefined reference' "$W/work/gles-build.log" | cut -c1-250 | sort | uniq | head -${N:-40}
tail -1 "$W/work/gles-build.log"
