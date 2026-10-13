# Shared settings for the aarch64 PortMaster build scripts (source this file).
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=mscharged-pm-build
SRC="${XSRC:-$W/work/xbuild-src}"          # (override: XSRC) the port at the pinned commit, with our patches (never ./upstream)
OUT="${XOUT:-$W/work/xbuild-out}"          # (override: XOUT) build products
SHIM_SRC="$W/work/sdl-shim"       # bmdhacks/SDL branch sdl2-backend at the pinned commit
PORT_REPO=https://github.com/yannicksuter/mscharged-port.git
PORT_COMMIT=64dcb73b              # mscharged-port 1.0.8 (origin/main); the previous base is the git tag base-d7cdfc47
SHIM_REPO=https://github.com/bmdhacks/SDL.git
SHIM_COMMIT=6057d79ba             # SDL 3.5.0-dev with the SDL2-delegating video/audio/joystick backends

# Runs a command in the build container with the workspace mounted at the same path.
in_container() {
  docker run --rm -u 0 -v mscharged-pm-cache:/cache "$IMAGE" chmod -R a+rwX /cache
  docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e CARGO_HOME=/cache/cargo \
    -v "$W:$W" -v mscharged-pm-cache:/cache -w "$W" "$IMAGE" bash -c "$*"
}

# Build directory name inside the prepared tree: HANDHELD=1 (default) the lean handheld game, HANDHELD=0 the full port,
# LTO=1 a separate directory for the link time optimized handheld build.
build_name() { echo "pm-aarch64$([ "${HANDHELD:-1}" = 1 ] && echo -handheld)${LTO:+-lto}"; }
