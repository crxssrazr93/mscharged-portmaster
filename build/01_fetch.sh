#!/bin/bash
# Prepares work/xbuild-src: the port at the pinned commit + our GLES and PortMaster patches + dependencies,
# and work/sdl-shim: the SDL3 fork with the SDL2 backend. Does not touch ./upstream (it only serves as an
# optional local mirror of the submodules when MIRROR=1, to avoid downloading ~1 GB again).
set -euo pipefail
source "$(dirname "$0")/common.sh"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always
if [ ! -d "$SRC/.git" ]; then
  if [ "${MIRROR:-0}" = 1 ] && [ -d "$W/upstream/.git" ]; then git clone -q "$W/upstream" "$SRC"
  else git clone -q --branch main --no-recurse-submodules "$PORT_REPO" "$SRC"; fi
fi
cd "$SRC"
git cat-file -e "$PORT_COMMIT^{commit}" 2>/dev/null || git fetch -q "$PORT_REPO" main
git checkout -q $([ "${RESET:-0}" = 1 ] && echo -f) "$PORT_COMMIT"
if [ "${MIRROR:-0}" = 1 ]; then
  for m in "$W"/upstream/.git/modules/extern/*; do
    git config "submodule.extern/$(basename "$m").url" "file://$m"
  done
fi
# The patches overlap (later ones touch the same files), so "already applied" cannot be decided per patch.
# Instead the series state is recorded as a hash of all patch files in a marker inside the checkout's .git.
# Marker matches: nothing to do. No marker and a clean tracked tree: apply the series. Anything else
# (patches changed, or hand edits in the tree): refuse, unless RESET=1 which rebuilds from the pinned commit
# (this discards uncommitted edits in the checkout, so turn them into patches first).
# TEST_CAPTURE=1 (with XSRC set to another directory) prepares a test tree instead: no handheld patch, plus the test only
# frame capture and scripted input (patches/test-capture/port), for tools/test_build.sh.
if [ "${TEST_CAPTURE:-0}" = 1 ]; then
  PORT_SERIES=("$W"/patches/port-gles "$W"/patches/port-pm "$W"/patches/port-perf "$W"/patches/test-capture/port)
else
  PORT_SERIES=("$W"/patches/port-gles "$W"/patches/port-pm "$W"/patches/port-perf "$W"/patches/port-handheld)
fi
SERIES_PATCHES=(); for d in "${PORT_SERIES[@]}"; do SERIES_PATCHES+=("$d"/*.patch); done; SERIES_PATCHES+=("$W"/patches/decomp-pm/*.patch)
MARK="$(git rev-parse --git-path mscharged-series.sha)"
SERIES_HASH=$(cat "${SERIES_PATCHES[@]}" | sha256sum | cut -d' ' -f1)
if [ -f "$MARK" ] && [ "$(cat "$MARK")" = "$SERIES_HASH" ]; then
  echo "patch series already applied ($SERIES_HASH)"
else
  if [ "${RESET:-0}" = 1 ]; then
    git reset -q --hard "$PORT_COMMIT"; git clean -fdq -- src patches tools cmake
  elif [ -f "$MARK" ] || [ -n "$(git status --porcelain --untracked-files=no)" ]; then
    echo "checkout has a different or unrecorded patch state; commit your edits as patches and rerun with RESET=1" >&2; exit 1
  fi
  for d in "${PORT_SERIES[@]}"; do
    for p in "$d"/*.patch; do git apply "$p"; echo "applied $(basename "$p")"; done
  done
  # Decomp host adaptations (appended to the port's own decomp series).
  for p in "$W"/patches/decomp-pm/*.patch; do
    cp "$p" patches/mscharged-decomp/
    grep -qxF "$(basename "$p")" patches/mscharged-decomp/series || echo "$(basename "$p")" >> patches/mscharged-decomp/series
  done
  echo "$SERIES_HASH" > "$MARK"
fi
python3 tools/setup_dependencies.py --graphics-backend gles
if [ ! -d "$SHIM_SRC/.git" ]; then git clone -q --branch sdl2-backend "$SHIM_REPO" "$SHIM_SRC"; fi
git -C "$SHIM_SRC" checkout -q "$SHIM_COMMIT"
