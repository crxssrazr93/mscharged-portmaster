#!/bin/bash
# Regenerates patches/port-gles/0001-gles-graphics-backend.patch from the working tree edits of the port clone
# (upstream/). The port clone is not committed to; its edits are carried only as this patch.
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$W/patches/port-gles"
cd "$W/upstream"
git add -N tools/prepare_gles_sources.py 2>/dev/null || true
git diff --binary --full-index -- . ':!build' ':!extern' > "$W/patches/port-gles/0001-gles-graphics-backend.patch"
wc -l "$W/patches/port-gles/0001-gles-graphics-backend.patch"
