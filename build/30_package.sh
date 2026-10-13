#!/bin/bash
# Assembles port/mscharged (stripped binaries and libraries) and builds the release zip dist/mscharged.zip.
set -euo pipefail
source "$(dirname "$0")/common.sh"
B="$SRC/build/pm-aarch64"
P="$W/port/mscharged"
mkdir -p "$P/libs.aarch64" "$P/libs.native" "$P/licenses" "$W/dist"
in_container "
set -euo pipefail
S=aarch64-linux-gnu-strip
\$S --strip-unneeded -o $P/mscharged.aarch64 $B/mscharged
for m in original_frontend original_main_credits; do \$S --strip-unneeded -o $P/mscharged_\${m}_module.so $B/mscharged_\${m}_module.so; done
\$S --strip-unneeded -o $P/libs.native/libSDL3.so.0 $OUT/sdl-native/libSDL3.so.0.4.10
"
# The working SDL3 shim is a committed prebuilt file; copy it unchanged.
cp "$W/vendor/sdl3-shim/libSDL3.so.0" "$P/libs.aarch64/libSDL3.so.0"
# Licenses of what is shipped
cp "$SRC/LICENSE" "$P/licenses/LICENSE.mscharged-port.txt"
cp "$SRC/extern/sdl/LICENSE.txt" "$P/licenses/LICENSE.SDL3.txt"
cp "$SHIM_SRC/LICENSE.txt" "$P/licenses/LICENSE.SDL3-sdl2-backend.txt"
cp "$B/prepared/aurora/source/LICENSE" "$P/licenses/LICENSE.aurora.txt"
cp "$W/port/cover.png" "$P/cover.png"
# Release layout: metadata inside the port folder, README renamed (like PortMaster's own build). The zip's launcher
# carries the "# PORTMASTER:" line, the launcher in port/ stays without it.
stage=$(mktemp -d); trap 'rm -rf "$stage"' EXIT
{ head -n 1 "$W/port/Mario Strikers Charged.sh"; echo "# PORTMASTER: mscharged.zip, Mario Strikers Charged.sh"; tail -n +2 "$W/port/Mario Strikers Charged.sh"; } > "$stage/Mario Strikers Charged.sh"
chmod 755 "$stage/Mario Strikers Charged.sh"
cp -r "$P" "$stage/"
rm -rf "$stage/mscharged/log.txt" "$stage/mscharged/logs" "$stage/mscharged/original-main-credits-data" "$stage/mscharged/mscharged.ini"
cp "$W/port/port.json" "$W/port/gameinfo.xml" "$W/port/screenshot.png" "$W/port/cover.png" "$stage/mscharged/"
cp "$W/port/README.md" "$stage/mscharged/mscharged.md"
chmod 755 "$stage/mscharged/mscharged.aarch64"
rm -f "$W/dist/mscharged.zip"
(cd "$stage" && zip -9 -r -q -X "$W/dist/mscharged.zip" .)
ls -l "$W/dist/mscharged.zip"; unzip -l "$W/dist/mscharged.zip"
