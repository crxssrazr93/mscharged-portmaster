#!/bin/bash
# Configures and cross builds the GLES port for aarch64 in the container (needs 01_fetch.sh and 10_sdl.sh first).
# Usage: build/20_build.sh [ninja target, default mscharged]
# HANDHELD=1 (default) builds the lean handheld game (preset gles-handheld, MSCHARGED_HANDHELD=ON, patches/aurora-handheld);
# HANDHELD=0 builds the full port (preset gles-release, launcher UI included) into build/pm-aarch64.
# LTO=1 turns on link time optimization (MSCHARGED_HANDHELD_LTO).
set -euo pipefail
source "$(dirname "$0")/common.sh"
HANDHELD="${HANDHELD:-1}"
if [ "$HANDHELD" = 1 ]; then PRESET=gles-handheld; B="$SRC/build/pm-aarch64-handheld"; else PRESET=gles-release; B="$SRC/build/pm-aarch64"; fi
export HANDHELD   # the preparer requires an ignored build directory inside the checkout
# Aurora patch series (GLES, glesfix, pm, gpu; see tools/aurora_series.sh for the skip switches).
SERIES="$OUT/aurora-series"
"$W/tools/aurora_series.sh" "$SERIES"
# Cache variables of the gles-release preset (resolved through its inheritance), so the build matches the PC one.
PRESET_ARGS=$(python3 - "$SRC/CMakePresets.json" "$PRESET" <<'PY'
import json, sys
presets = {p["name"]: p for p in json.load(open(sys.argv[1]))["configurePresets"]}
def resolve(name):
    p = presets[name]; v = {}
    for parent in ([p["inherits"]] if isinstance(p.get("inherits"), str) else p.get("inherits", [])): v.update(resolve(parent))
    v.update(p.get("cacheVariables", {})); return v
for k, v in resolve(sys.argv[2]).items():
    print("-D%s=%s" % (k, ("ON" if v else "OFF") if isinstance(v, bool) else v))
PY
)
in_container "
set -euo pipefail
cd $SRC
cmake -S . -B $B -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=$W/docker/toolchain-aarch64.cmake \
  $(echo $PRESET_ARGS) -DMSCHARGED_AURORA_EXTRA_PATCH_DIR=$SERIES -DPython3_EXECUTABLE=/usr/bin/python3 -DBUILD_TESTING=OFF ${LTO:+-DMSCHARGED_HANDHELD_LTO=ON} -DMSCHARGED_FORMAT_PREPARED_SOURCES=OFF \
  -DCMAKE_SKIP_RPATH=ON -DMSCHARGED_SDL3_LIBRARY=$OUT/sdl-shim/libSDL3.so.0.5.0 -DRust_CARGO_TARGET=aarch64-unknown-linux-gnu
cmake --build $B --target ${1:-mscharged} -j${JOBS:-6} -- -k ${KEEP:-1}
"
