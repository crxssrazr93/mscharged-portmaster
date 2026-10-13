# Cross build environment for the aarch64 PortMaster build of Mario Strikers Charged.
#
# Host:    Ubuntu 24.04 (x86_64) with clang 19. The port's sources use C++20 and clang/GCC 15 only flags,
#          which GCC 10 (the compiler that matches an old sysroot) cannot build.
# Sysroot: Ubuntu 20.04 "focal" arm64 (glibc 2.31, libstdc++ 10 = GLIBCXX_3.4.28), unpacked with debootstrap
#          into /sysroot. That is the same floor as Debian 11 (Bullseye), the oldest userland PortMaster
#          firmwares ship, and the binary can only link against symbols that exist there. libstdc++ stays a
#          dynamic dependency (the game modules are shared objects that share it with the executable), so a
#          bundled copy is deliberately NOT shipped: an old libstdc++ first in LD_LIBRARY_PATH would break the
#          newer Mesa drivers some firmwares load.
# Cross compiling instead of QEMU emulation: minutes instead of many hours, nothing registered with binfmt_misc.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg pkg-config make tcl ninja-build file xz-utils unzip zip cmake python3 \
      build-essential clang-19 llvm-19 binutils-aarch64-linux-gnu debootstrap \
 && rm -rf /var/lib/apt/lists/*
RUN debootstrap --foreign --variant=minbase --arch=arm64 --no-check-gpg --components=main,universe --extra-suites=focal-updates \
      --include=libc6-dev,libstdc++-10-dev,libgcc-10-dev,linux-libc-dev,libgles-dev,libegl-dev,libdrm-dev,libgbm-dev,libasound2-dev,libudev-dev \
      focal /sysroot http://ports.ubuntu.com/ubuntu-ports > /tmp/debootstrap.log 2>&1 \
 || { tail -20 /tmp/debootstrap.log; exit 1; }
# --foreign only unpacks the base system: unpack the requested development packages (and dependencies) too.
RUN cd /sysroot/var/cache/apt/archives && for d in *.deb; do dpkg-deb -x "$d" /sysroot; done \
 && ls /sysroot/usr/lib/gcc/aarch64-linux-gnu/ && rm -rf /sysroot/var/cache/apt/archives/*.deb
# Absolute symlinks (libdl.so -> /lib/aarch64-linux-gnu/libdl.so.2, ...) must resolve inside the sysroot.
RUN find /sysroot -type l -lname '/*' | while read -r l; do \
      t=$(readlink "$l"); ln -sfn "$(realpath -m --relative-to="$(dirname "$l")" "/sysroot$t")" "$l"; done
# Compiler and linker drivers for the aarch64 target (also used by Rust and C crates through cargo).
RUN for t in clang clang++; do \
      printf '#!/bin/sh\nexec %s-19 --target=aarch64-linux-gnu --sysroot=/sysroot --gcc-install-dir=/sysroot/usr/lib/gcc/aarch64-linux-gnu/10 --ld-path=/usr/bin/aarch64-linux-gnu-ld -Wno-unused-command-line-argument "$@"\n' "$t" \
        > /usr/local/bin/aarch64-$t; \
      chmod +x /usr/local/bin/aarch64-$t; done
# Rust for nod (disc reader), built through Corrosion for the aarch64 target.
ARG RUST_VERSION=1.90.0
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} \
      --target aarch64-unknown-linux-gnu && chmod -R a+rwX /opt/rustup /opt/cargo
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-clang \
    CC_aarch64_unknown_linux_gnu=aarch64-clang CXX_aarch64_unknown_linux_gnu=aarch64-clang++ \
    AR_aarch64_unknown_linux_gnu=llvm-ar-19 \
    PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_SYSROOT_DIR=/sysroot \
    PKG_CONFIG_LIBDIR=/sysroot/usr/lib/aarch64-linux-gnu/pkgconfig:/sysroot/usr/share/pkgconfig
# Ubuntu 24.04 ships CMake 3.28; the WHOLE_ARCHIVE link usage in the GLES patches needs 3.31 or newer.
ARG CMAKE_VERSION=3.31.6
RUN curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    | tar xz -C /opt && ln -sf /opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/* /usr/local/bin/
# User mode emulation, only to smoke test the aarch64 binary (build/40_verify.sh): no binfmt registration needed.
RUN apt-get update && apt-get install -y --no-install-recommends qemu-user-static && rm -rf /var/lib/apt/lists/*
WORKDIR /src
