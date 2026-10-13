#!/bin/bash
# Regenerates patches/test-capture/port/0001-test-capture.patch: the test-only edits of the port
# (virtual time, scripted input, capture) as the difference between work/cmp/orig (the shipping
# files) and upstream/. Run after editing the test hooks in upstream/.
set -e
W="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$W/patches/test-capture/port"
OUT=$W/patches/test-capture/port/0001-test-capture.patch
: > "$OUT"
cd "$W/work/cmp/orig"
for f in $(find . -type f | sed 's#^\./##' | sort); do
  diff -u --label a/$f --label b/$f "$f" "$W/upstream/$f" >> "$OUT" || true
done
for f in src/testcapture/test_capture.h src/testcapture/test_capture.cpp; do
  diff -u --label /dev/null --label b/$f /dev/null "$W/upstream/$f" >> "$OUT" || true
done
wc -l "$OUT"
