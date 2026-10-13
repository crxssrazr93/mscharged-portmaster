#!/bin/bash
# Checks the packaged binaries: required libraries, glibc/libstdc++ symbol versions, program header layout, and a
# start under qemu-aarch64 user mode (prints the help text and the version).
set -euo pipefail
source "$(dirname "$0")/common.sh"
P="$W/port/mscharged"
in_container "
cd $P
RE=aarch64-linux-gnu-readelf; OD=aarch64-linux-gnu-objdump
for f in mscharged.aarch64 mscharged_original_frontend_module.so mscharged_original_main_credits_module.so libs.aarch64/libSDL3.so.0 libs.native/libSDL3.so.0; do
  echo \"== \$f\"
  echo -n 'NEEDED: '; \$RE -d \$f | sed -n 's/.*Shared library: \[\(.*\)\]/\1/p' | tr '\n' ' '; echo
  echo -n 'RUNPATH/RPATH: '; \$RE -d \$f | grep -E 'RUNPATH|RPATH' || echo none
  echo -n 'max GLIBC: '; \$OD -T \$f | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
  echo -n 'max GLIBCXX: '; (\$OD -T \$f | grep -o 'GLIBCXX_[0-9.]*' | sort -uV | tail -1) || true; echo
  echo -n 'max CXXABI: '; (\$OD -T \$f | grep -o 'CXXABI_[0-9.]*' | sort -uV | tail -1) || true; echo
  \$RE -lW \$f | awk '/PHDR/{print \"PHDR p_vaddr==p_offset: \" ((\$2==\$3) ? \"OK\" : \"BROKEN\")}'
done
echo
echo '== qemu-aarch64 user mode start'
qemu-aarch64-static -L /sysroot -E LD_LIBRARY_PATH=$P/libs.aarch64 ./mscharged.aarch64 --help 2>&1 | head -30 || true
echo '--- version'
qemu-aarch64-static -L /sysroot -E LD_LIBRARY_PATH=$P/libs.aarch64 ./mscharged.aarch64 --version 2>&1 | head -5 || true
"
