#!/bin/bash
# Builds the cross build container (Ubuntu 20.04, glibc 2.31, g++ 10, Rust, CMake 3.31).
set -euo pipefail
source "$(dirname "$0")/common.sh"
docker build -t "$IMAGE" "$W/docker"
