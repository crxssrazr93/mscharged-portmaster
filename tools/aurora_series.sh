#!/bin/bash
# Assembles the Aurora extra patch directory (applied after the port's own patches/aurora 0001 to 0089) from the
# committed series, in this order: patches/aurora-gles, patches/aurora-glesfix (skip: GLESFIX=0),
# patches/aurora-pm (skip: AURORA_PM=0), patches/aurora-gpu (skip: AURORA_GPU=0), patches/aurora-handheld (only with
# HANDHELD=1: the lean Aurora of the handheld build), then any extra patch files given
# as arguments (test builds pass patches/test-capture/aurora/0001-virtual-clock.patch).
# patches/aurora-gpu-wip is pending work and is never part of the series.
# Usage: tools/aurora_series.sh <out dir> [extra patch file ...]
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
O=$1; shift
rm -rf "$O"; mkdir -p "$O"
cp "$W"/patches/aurora-gles/*.patch "$O/"; cp "$W/patches/aurora-gles/series" "$O/series"; cp "$W/patches/aurora-gles/base" "$O/base"
add_dir() { for p in "$W/patches/$1"/*.patch; do [ -e "$p" ] || continue; cp "$p" "$O/"; basename "$p" >> "$O/series"; done; }
[ "${GLESFIX:-1}" = 1 ] && add_dir aurora-glesfix
[ "${AURORA_PM:-1}" = 1 ] && add_dir aurora-pm
[ "${AURORA_GPU:-1}" = 1 ] && add_dir aurora-gpu
[ "${HANDHELD:-0}" = 1 ] && add_dir aurora-handheld
for p in "$@"; do cp "$p" "$O/"; basename "$p" >> "$O/series"; done
