# CMake toolchain file for the cross build container (see docker/Dockerfile).
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc-10)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++-10)
set(CMAKE_AR aarch64-linux-gnu-ar)
set(CMAKE_RANLIB aarch64-linux-gnu-ranlib)
set(CMAKE_STRIP aarch64-linux-gnu-strip)
# Plain ARMv8-A so the binary runs on every PortMaster SoC (Cortex-A35 to A55), tuned for the
# in-order Cortex-A53 class that most handhelds use.
set(CMAKE_C_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53")
set(CMAKE_CXX_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53")
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
