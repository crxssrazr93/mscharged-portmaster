# Cross build environment for the aarch64 PortMaster build of Mario Strikers Charged.
#
# Base: Ubuntu 20.04. Its glibc 2.31 and libstdc++ 10 (GLIBCXX_3.4.28) are the same floor as
# Debian 11 (Bullseye), the oldest userland the PortMaster firmwares still ship, and the
# aarch64 sysroot below is what the binary links against, so it cannot pick up newer symbols.
# Cross compiling (x86_64 host, aarch64 target) is used instead of QEMU emulation: the build
# takes minutes instead of many hours, and nothing has to be registered with binfmt_misc.
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN printf '%s\n' \
      "deb [arch=amd64] http://archive.ubuntu.com/ubuntu focal main universe" \
      "deb [arch=amd64] http://archive.ubuntu.com/ubuntu focal-updates main universe" \
      "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main universe" \
      "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports focal main universe" \
      "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports focal-updates main universe" \
      "deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports focal-security main universe" \
      > /etc/apt/sources.list \
 && dpkg --add-architecture arm64 && apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git gnupg pkg-config build-essential make tcl ninja-build file xz-utils unzip zip \
      gcc-10 g++-10 gcc-10-aarch64-linux-gnu g++-10-aarch64-linux-gnu binutils-aarch64-linux-gnu \
      libc6-dev-arm64-cross \
      libgles-dev:arm64 libegl-dev:arm64 libdrm-dev:arm64 libgbm-dev:arm64 \
      libasound2-dev:arm64 libudev-dev:arm64 libdbus-1-dev:arm64 \
 && rm -rf /var/lib/apt/lists/*
# The port needs Python 3.10 and CMake 3.25; Ubuntu 20.04 ships 3.8 and 3.16 (the host side tools below only
# run the build scripts and do not influence the aarch64 binary).
ARG PYTHON_TAG=20241016
ARG PYTHON_VERSION=3.10.15
RUN curl -fsSL https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_TAG}/cpython-${PYTHON_VERSION}+${PYTHON_TAG}-x86_64-unknown-linux-gnu-install_only.tar.gz \
    | tar xz -C /opt && ln -sf /opt/python/bin/python3.10 /usr/local/bin/python3 && ln -sf /opt/python/bin/python3.10 /usr/local/bin/python3.10
ARG CMAKE_VERSION=3.31.6
RUN curl -fsSL https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
    | tar xz -C /opt && ln -s /opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/* /usr/local/bin/
# Rust for nod (disc reader), built through Corrosion for the aarch64 target.
ARG RUST_VERSION=1.90.0
ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION} \
      --target aarch64-unknown-linux-gnu && chmod -R a+rwX /opt/rustup /opt/cargo
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc-10 \
    CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc-10 \
    CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++-10 \
    AR_aarch64_unknown_linux_gnu=aarch64-linux-gnu-ar \
    PKG_CONFIG_ALLOW_CROSS=1 PKG_CONFIG_LIBDIR=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig \
    PKG_CONFIG_SYSROOT_DIR=/
WORKDIR /src
