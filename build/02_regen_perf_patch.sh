#!/bin/bash
# Regenerates patches/port-perf/0001-native-ax-perf.patch from the edits in work/xbuild-src: the diff between
# (pinned commit + port-gles + port-pm patches) and the checkout's src, cmake and tools directories.
# Run it after editing the perf code in the checkout, then commit the patch. The series marker is refreshed so
# that 01_fetch.sh keeps accepting the checkout.
set -euo pipefail
source "$(dirname "$0")/common.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git clone -q "$SRC" "$T/base"; cd "$T/base"
git checkout -q "$PORT_COMMIT"
for p in "$W"/patches/port-gles/*.patch "$W"/patches/port-pm/*.patch; do git apply "$p"; done
git add -A; git -c user.name=x -c user.email=x@x commit -qm base
for d in src cmake tools; do rsync -a --delete "$SRC/$d/" "$T/base/$d/"; done
git add -A
git diff --cached --binary > "$W/patches/port-perf/0001-native-ax-perf.patch"
cd "$SRC"
cat "$W"/patches/port-gles/*.patch "$W"/patches/port-pm/*.patch "$W"/patches/port-perf/*.patch "$W"/patches/decomp-pm/*.patch \
  | sha256sum | cut -d' ' -f1 > "$(git rev-parse --git-path mscharged-series.sha)"
git -C "$W" diff --stat -- patches/port-perf | tail -1
