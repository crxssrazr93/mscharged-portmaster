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
git checkout -q "$PORT_COMMIT"
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
SERIES_PATCHES=("$W"/patches/port-gles/*.patch "$W"/patches/port-pm/*.patch "$W"/patches/port-perf/*.patch "$W"/patches/decomp-pm/*.patch)
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
  for p in "$W"/patches/port-gles/*.patch "$W"/patches/port-pm/*.patch "$W"/patches/port-perf/*.patch; do
    git apply "$p"; echo "applied $(basename "$p")"
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
