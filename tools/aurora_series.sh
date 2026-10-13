#!/bin/bash
# Assembles an Aurora extra patch directory from the committed series: patches/aurora-gles, then
# patches/aurora-glesfix (skipped with GLESFIX=0), then any extra patch files given as arguments.
# Usage: tools/aurora_series.sh <out dir> [extra patch file ...]
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
O=$1; shift
rm -rf "$O"; mkdir -p "$O"
cp "$W"/patches/aurora-gles/*.patch "$O/"; cp "$W/patches/aurora-gles/series" "$O/series"; cp "$W/patches/aurora-gles/base" "$O/base"
if [ "${GLESFIX:-1}" = 1 ]; then
  for p in "$W"/patches/aurora-glesfix/*.patch; do [ -e "$p" ] || continue; cp "$p" "$O/"; basename "$p" >> "$O/series"; done
fi
for p in "$@"; do cp "$p" "$O/"; basename "$p" >> "$O/series"; done
