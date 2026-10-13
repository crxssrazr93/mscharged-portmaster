#!/bin/bash
# Builds the two comparison binaries: upstream/build/gles-cmp (GLES) and upstream/build/vk-cmp (Vulkan),
# both with the test capture hooks (patches/test-capture). Never touches build/release or build/gles-release.
# Usage: tests/compare/build_cmp.sh [gles|vk|both]   (default both). The GLES Aurora comes from the worktree
# committed series patches/aurora-gles + patches/aurora-glesfix (tools/aurora_series.sh) plus the virtual clock.
set -e
W="$(cd "$(dirname "$0")/../.." && pwd)"
WHAT=${1:-both}
TAG=${TAG:-}
S=$W/work/cmp
if [ "$WHAT" != vk ]; then
  # One build directory (build/gles-cmp, incremental). TAG names a copy of the binary (mscharged$TAG next to it) so a
  # baseline (GLESFIX=0: without patches/aurora-glesfix) and a fixed build can both be run later.
  "$W/tools/aurora_series.sh" "$S/aurora-gles-test" "$W/patches/test-capture/aurora/0001-virtual-clock.patch"
  cd "$W/upstream"
  cmake -S . -B build/gles-cmp -DMSCHARGED_TEST_CAPTURE=ON -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$S/aurora-gles-test" > "$S/gles-cmp-configure.log" 2>&1
  ninja -C build/gles-cmp mscharged > "$S/gles-cmp-build.log" 2>&1 || { grep -E "error|FAILED" "$S/gles-cmp-build.log" | head; exit 1; }
  tail -1 "$S/gles-cmp-build.log"
  [ -z "$TAG" ] || cp build/gles-cmp/mscharged "build/gles-cmp/mscharged$TAG"
fi
if [ "$WHAT" != gles ]; then
  cd "$W/upstream"
  cmake -S . -B build/vk-cmp -DMSCHARGED_TEST_CAPTURE=ON -DMSCHARGED_AURORA_TEST_PATCH_DIR="$W/patches/test-capture/aurora" > "$S/vk-cmp-configure.log" 2>&1
  ninja -C build/vk-cmp mscharged > "$S/vk-cmp-build.log" 2>&1 || { grep -E "error|FAILED" "$S/vk-cmp-build.log" | head; exit 1; }
  tail -1 "$S/vk-cmp-build.log"
fi
