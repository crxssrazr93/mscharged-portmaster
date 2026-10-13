#!/bin/bash
# Builds both SDL3 flavours for aarch64 inside the container:
#   shim   : bmdhacks/SDL sdl2-backend (video, audio and gamepads delegate to the firmware's own SDL2,
#            the way the PortMaster SDL3 ports run). Default.
#   native : the port's pinned SDL 3.4.10 with KMSDRM + EGL/GLES (loads libdrm/libgbm/libEGL at run time).
#            Fallback for firmwares without a usable SDL2, selected with SDL_BACKEND=native in the launcher.
set -euo pipefail
source "$(dirname "$0")/common.sh"
in_container "
set -euo pipefail
TC=$W/docker/toolchain-aarch64.cmake
rm -rf $OUT/sdl-shim $OUT/sdl-native-build; mkdir -p $OUT/sdl-shim $OUT/sdl-native
cmake -S $SHIM_SRC -B $OUT/sdl-shim-build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=\$TC \
  -DSDL_SDL2_BACKEND=ON -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_TEST_LIBRARY=OFF \
  -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_KMSDRM=OFF -DSDL_PIPEWIRE=OFF -DSDL_PULSEAUDIO=OFF -DSDL_ALSA=OFF \
  -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_JACK=OFF -DSDL_OFFSCREEN=OFF -DSDL_DUMMYVIDEO=OFF -DSDL_DUMMYAUDIO=OFF \
  -DSDL_DISKAUDIO=OFF -DSDL_VULKAN=OFF -DSDL_GPU=OFF -DSDL_RENDER_GPU=OFF -DSDL_INSTALL=OFF -DSDL_UNIX_CONSOLE_BUILD=ON
cmake --build $OUT/sdl-shim-build -j6
cp -a $OUT/sdl-shim-build/libSDL3.so* $OUT/sdl-shim/
cmake -S $SRC/extern/sdl -B $OUT/sdl-native-build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=\$TC \
  -DSDL_SHARED=ON -DSDL_STATIC=OFF -DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF -DSDL_TEST_LIBRARY=OFF -DSDL_INSTALL=OFF \
  -DSDL_KMSDRM=ON -DSDL_KMSDRM_SHARED=ON -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_VULKAN=OFF -DSDL_GPU=OFF -DSDL_RENDER_GPU=OFF \
  -DSDL_OPENGLES=ON -DSDL_OPENGL=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF \
  -DSDL_ALSA=ON -DSDL_ALSA_SHARED=ON -DSDL_LIBUDEV=ON -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_UNIX_CONSOLE_BUILD=ON
cmake --build $OUT/sdl-native-build -j6
cp -a $OUT/sdl-native-build/libSDL3.so* $OUT/sdl-native/
ls -la $OUT/sdl-shim $OUT/sdl-native
"
