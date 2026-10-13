#!/bin/bash
# Prepares a fresh clone of yannicksuter/mscharged-port (in ./upstream) for the GLES build.
#  1. applies patches/port-gles (CMake option MSCHARGED_GRAPHICS_BACKEND=gles, preset gles-release, GL replacements
#     for the port's wgpu uses),
#  2. fetches the dependencies of the GLES build (no Dawn, plus Abseil),
#  3. configures the gles-release preset, which applies patches/aurora (84 Charged patches) and then
#     patches/aurora-gles (this workspace) to the pinned Aurora checkout.
# Usage: ./prepare.sh [--no-configure]
set -euo pipefail
W="$(cd "$(dirname "$0")" && pwd)"
cd "$W/upstream"
for p in "$W"/patches/port-gles/*.patch; do
  if git apply --check "$p" 2>/dev/null; then
    git apply "$p"; echo "applied $(basename "$p")"
  elif git apply -R --check "$p" 2>/dev/null; then
    echo "already applied: $(basename "$p")"
  else
    echo "cannot apply $(basename "$p") (upstream is not the expected revision)" >&2; exit 1
  fi
done
python3 tools/setup_dependencies.py --graphics-backend gles
[ "${1:-}" = "--no-configure" ] || cmake --preset gles-release
