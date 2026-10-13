#!/bin/bash
# Regenerates patches/aurora-gles from the Aurora development worktree (branch gles-forkmerge),
# as the difference between the Charged-patched Aurora base (branch charged-base) and its tip.
# Usage: tools/export_aurora_gles.sh [worktree, default work/aurora-charged]
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
TREE=${1:-$W/work/aurora-charged}
OUT=$W/patches/aurora-gles
rm -rf "$OUT"; mkdir -p "$OUT"
cd "$TREE"
n=0
: > "$OUT/series"
emit() { # name, pathspec...
  local name=$1; shift
  n=$((n + 1))
  local file; file=$(printf '%04d-%s.patch' "$n" "$name")
  git diff --binary --full-index charged-base HEAD -- "$@" > "$OUT/$file"
  if [ -s "$OUT/$file" ]; then echo "$file" >> "$OUT/series"; else rm "$OUT/$file"; n=$((n - 1)); fi
}
emit remove-dawn-and-wgpu-sources lib/dawn lib/webgpu/gpu.cpp lib/webgpu/gpu_cache.cpp lib/webgpu/wgpu.hpp include/aurora/webgpu.hpp cmake/AuroraDawnProvider.cmake
emit add-gles-device-layer lib/gl lib/webgpu/gpu.hpp lib/webgpu/gpu_prof.cpp lib/webgpu/gpu_prof.hpp lib/webgpu/sdl2shim_present.cpp lib/webgpu/sdl2shim_present.hpp include/aurora/gl.hpp
emit gles-gfx-recording lib/gfx
emit gles-gx-translation lib/gx include/aurora/gfx.hpp
emit gles-host-and-build lib/aurora.cpp lib/imgui.cpp lib/imgui.hpp lib/rmlui lib/rmlui.cpp lib/rmlui.hpp lib/window.cpp lib/internal.hpp lib/dolphin cmake ':(exclude)cmake/AuroraDawnProvider.cmake' extern tests CMakeLists.txt
# anything else that differs must not be silently dropped
rest=$(git diff --name-only charged-base HEAD | grep -v -E '^(lib/dawn|lib/webgpu|lib/gl/|lib/gfx/|lib/gx/|include/aurora/(gfx|gl|webgpu)\.hpp|lib/(aurora|imgui|rmlui|window|internal)|lib/dolphin|cmake/|extern/|tests/|CMakeLists.txt)' || true)
if [ -n "$rest" ]; then echo "uncovered files:"; echo "$rest"; exit 1; fi
echo "base: $(git rev-parse charged-base^{tree})" > /dev/null
git rev-parse charged-base~84 > "$OUT/base" 2>/dev/null || true
cat "$OUT/series"
