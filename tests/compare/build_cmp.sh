#!/bin/bash
# Builds the two comparison binaries: upstream/build/gles-cmp (GLES) and upstream/build/vk-cmp (Vulkan),
# both with the test capture hooks (patches/test-capture). Never touches build/release or build/gles-release.
# Usage: tests/compare/build_cmp.sh [gles|vk|both]   (default both). The GLES Aurora comes from the worktree
# work/aurora-charged (commit first): it is re-exported to patches/aurora-gles like tools/gles_build.sh does.
set -e
W="$(cd "$(dirname "$0")/../.." && pwd)"
WHAT=${1:-both}
S=$W/work/cmp
if [ "$WHAT" != vk ]; then
  "$W/tools/export_aurora_gles.sh" > /dev/null
  rm -rf "$S/aurora-gles-test"; mkdir -p "$S/aurora-gles-test"
  cp "$W"/patches/aurora-gles/*.patch "$S/aurora-gles-test/"
  cp "$W/patches/test-capture/aurora/0001-virtual-clock.patch" "$S/aurora-gles-test/0099-virtual-clock.patch"
  (cat "$W/patches/aurora-gles/series"; echo 0099-virtual-clock.patch) > "$S/aurora-gles-test/series"
  cp "$W/patches/aurora-gles/base" "$S/aurora-gles-test/base"
  cd "$W/upstream"
  cmake -S . -B build/gles-cmp -DMSCHARGED_TEST_CAPTURE=ON -DMSCHARGED_AURORA_EXTRA_PATCH_DIR="$S/aurora-gles-test" > "$S/gles-cmp-configure.log" 2>&1
  ninja -C build/gles-cmp mscharged > "$S/gles-cmp-build.log" 2>&1 || { grep -E "error|FAILED" "$S/gles-cmp-build.log" | head; exit 1; }
  tail -1 "$S/gles-cmp-build.log"
fi
if [ "$WHAT" != gles ]; then
  cd "$W/upstream"
  cmake -S . -B build/vk-cmp -DMSCHARGED_TEST_CAPTURE=ON -DMSCHARGED_AURORA_TEST_PATCH_DIR="$W/patches/test-capture/aurora" > "$S/vk-cmp-configure.log" 2>&1
  ninja -C build/vk-cmp mscharged > "$S/vk-cmp-build.log" 2>&1 || { grep -E "error|FAILED" "$S/vk-cmp-build.log" | head; exit 1; }
  tail -1 "$S/vk-cmp-build.log"
fi
