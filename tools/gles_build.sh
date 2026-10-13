#!/bin/bash
# Re-export the Aurora GLES patches from the worktree, re-prepare sources and build the GLES port.
# Usage: tools/gles_build.sh [target, default mscharged]
set -e
W="$(cd "$(dirname "$0")/.." && pwd)"
"$W/tools/export_aurora_gles.sh" > /dev/null
cd "$W/upstream"
cmake --preset gles-release > "$W/work/gles-configure.log" 2>&1 || { tail -30 "$W/work/gles-configure.log"; exit 1; }
cmake --build build/gles-release --target "${1:-mscharged}" -j8 -- -k 0 > "$W/work/gles-build.log" 2>&1 || true
grep -E 'error:|FAILED|undefined reference' "$W/work/gles-build.log" | cut -c1-250 | sort | uniq | head -${N:-40}
tail -1 "$W/work/gles-build.log"
