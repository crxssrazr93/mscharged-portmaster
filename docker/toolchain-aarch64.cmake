# CMake toolchain file for the cross build container (see docker/Dockerfile).
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-clang)
set(CMAKE_CXX_COMPILER aarch64-clang++)
set(CMAKE_AR llvm-ar-19)
set(CMAKE_RANLIB llvm-ranlib-19)
set(CMAKE_STRIP llvm-strip-19)
set(CMAKE_SYSROOT /sysroot)
# Plain ARMv8-A so the binary runs on every PortMaster SoC (Cortex-A35 to A55), tuned for the
# in-order Cortex-A53 class that most handhelds use. libstdc++ 10 lacks a few C++20 pieces: the compat
# header backfills them (guarded, so it is a no-op with a newer library).
set(CMAKE_C_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53")
set(CMAKE_CXX_FLAGS_INIT "-march=armv8-a -mtune=cortex-a53 -DMSCHARGED_STREAM_FLOAT_PARSE -include ${CMAKE_CURRENT_LIST_DIR}/std20_compat.hpp")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--as-needed")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-Wl,--as-needed")
set(CMAKE_FIND_ROOT_PATH /sysroot)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
