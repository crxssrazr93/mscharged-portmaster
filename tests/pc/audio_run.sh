#!/bin/bash
# Offscreen run of the PC audio build with the audio statistics on, through the scripted menus (tests/pc/gles_match_actions.txt).
# Usage: tests/pc/audio_run.sh <name> [seconds, default 110]   (output in work/audio-runs/<name>/game.log)
# Environment: BUILD (build dir, default work/xbuild-audio/build/pc-audio), the MSCHARGED_AUDIO_* switches pass through,
#   e.g. MSCHARGED_AUDIO_STALL=600,150 (the owner stays away 150 ms every 600 ms, from second 20 on).
W="$(cd "$(dirname "$0")/../.." && pwd)"
export SDL_AUDIODRIVER=dummy MSCHARGED_AUDIOSTATS=1
export BUILD=${BUILD:-$W/work/xbuild-audio/build/pc-audio} ACTIONS=$W/tests/pc/gles_match_actions.txt EVERY=${2:-110}
mkdir -p "$W/work/audio-runs"
"$W/tests/pc/gles_boot.sh" "$W/work/audio-runs/$1" "${2:-110}" > "$W/work/audio-runs/$1.out" 2>&1
grep -c audiostats "$W/work/audio-runs/$1/game.log"
