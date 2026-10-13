# Shared settings for the aarch64 PortMaster build scripts (source this file).
W="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=mscharged-pm-build
SRC="$W/work/xbuild-src"          # the port at the pinned commit, with our patches (never ./upstream)
OUT="$W/work/xbuild-out"          # build products
SHIM_SRC="$W/work/sdl-shim"       # bmdhacks/SDL branch sdl2-backend at the pinned commit
PORT_REPO=https://github.com/yannicksuter/mscharged-port.git
PORT_COMMIT=d7cdfc47              # commit the GLES patches were made against
SHIM_REPO=https://github.com/bmdhacks/SDL.git
SHIM_COMMIT=6057d79ba             # SDL 3.5.0-dev with the SDL2-delegating video/audio/joystick backends

# Runs a command in the build container with the workspace mounted at the same path.
in_container() {
  docker run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e CARGO_HOME=/cache/cargo \
    -v "$W:$W" -v mscharged-pm-cache:/cache -w "$W" "$IMAGE" bash -c "$*"
}
