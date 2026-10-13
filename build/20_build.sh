#!/bin/bash
# Configures and cross builds the GLES port for aarch64 in the container (needs 01_fetch.sh and 10_sdl.sh first).
# Usage: build/20_build.sh [ninja target, default mscharged]
set -euo pipefail
source "$(dirname "$0")/common.sh"
B="$SRC/build/pm-aarch64"   # the preparer requires an ignored build directory inside the checkout
# Aurora patch series: our GLES series followed by the PortMaster compatibility patches (patches/aurora-pm).
SERIES="$OUT/aurora-series"; rm -rf "$SERIES"; mkdir -p "$SERIES"
cp "$W"/patches/aurora-gles/*.patch "$SERIES/"; cp "$W/patches/aurora-gles/series" "$SERIES/series"
for p in "$W"/patches/aurora-pm/*.patch; do [ -e "$p" ] || continue; cp "$p" "$SERIES/"; basename "$p" >> "$SERIES/series"; done
# Cache variables of the gles-release preset (resolved through its inheritance), so the build matches the PC one.
PRESET_ARGS=$(python3 - "$SRC/CMakePresets.json" <<'PY'
import json, sys
presets = {p["name"]: p for p in json.load(open(sys.argv[1]))["configurePresets"]}
def resolve(name):
    p = presets[name]; v = {}
    for parent in ([p["inherits"]] if isinstance(p.get("inherits"), str) else p.get("inherits", [])): v.update(resolve(parent))
    v.update(p.get("cacheVariables", {})); return v
for k, v in resolve("gles-release").items():
    print("-D%s=%s" % (k, ("ON" if v else "OFF") if isinstance(v, bool) else v))
PY
)
in_container "
set -euo pipefail
cd $SRC
cmake -S . -B $B -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$W/docker/toolchain-aarch64.cmake \
  $(echo $PRESET_ARGS) -DMSCHARGED_AURORA_EXTRA_PATCH_DIR=$SERIES -DPython3_EXECUTABLE=/usr/bin/python3 -DBUILD_TESTING=OFF -DMSCHARGED_FORMAT_PREPARED_SOURCES=OFF \
  -DMSCHARGED_SDL3_LIBRARY=$OUT/sdl-shim/libSDL3.so.0.5.0 -DRust_CARGO_TARGET=aarch64-unknown-linux-gnu
cmake --build $B --target ${1:-mscharged} -j${JOBS:-6} -- -k ${KEEP:-1}
"
