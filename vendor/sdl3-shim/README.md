# SDL3 shim (prebuilt, aarch64)

`libSDL3.so.0` is the SDL3 build with the `sdl2` video driver that wraps the firmware SDL2 of PortMaster devices and publishes its EGL display, context and `gl_get_proc` as `SDL.window.sdl2_backend.*` window properties. The GLES Aurora backend needs those properties on the device.

Source of this file: the Dusklight PortMaster port by bmdhacks (branch `dusklight` of github.com/bmdhacks/PortMaster-MV-New, `ports/dusklight/dusklight/libs.aarch64/libSDL3.so.0`), sha256 below. SDL is under the zlib license (see `port/mscharged/licenses`).

The public `sdl2-backend` branch of github.com/bmdhacks/SDL (commit 6057d79) does not publish these properties, so a build from it fails on the device with "the shim published no EGLDisplay/getProc" (tested on an RG35XX H, Knulli, 2026-10-13). The matching source is not public yet.
a4e016fcf82e2f3f4479f69c8c0ef8af559e3ad818e077014958e00fbbe8215d  vendor/sdl3-shim/libSDL3.so.0
