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
apply() {  # apply a patch once
  if git apply --check "$1" 2>/dev/null; then git apply "$1"; echo "applied $(basename "$1")"
  elif git apply -R --check "$1" 2>/dev/null; then echo "already applied: $(basename "$1")"
  else echo "cannot apply $1" >&2; exit 1; fi
}
for p in "$W"/patches/port-gles/*.patch "$W"/patches/port-pm/*.patch; do apply "$p"; done
# Decomp host adaptations (appended to the port's own decomp series).
for p in "$W"/patches/decomp-pm/*.patch; do
  cp "$p" patches/mscharged-decomp/
  grep -qxF "$(basename "$p")" patches/mscharged-decomp/series || echo "$(basename "$p")" >> patches/mscharged-decomp/series
done
python3 tools/setup_dependencies.py --graphics-backend gles
if [ ! -d "$SHIM_SRC/.git" ]; then git clone -q --branch sdl2-backend "$SHIM_REPO" "$SHIM_SRC"; fi
git -C "$SHIM_SRC" checkout -q "$SHIM_COMMIT"
