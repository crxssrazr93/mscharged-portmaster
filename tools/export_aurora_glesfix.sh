#!/bin/bash
# Re-exports patches/aurora-glesfix (verified GLES render fixes and env-gated test aids) from the worktree
# work/aurora-glesfix (branch glesfix, one commit per fix on top of the commit that matches patches/aurora-gles).
# Usage: tools/export_aurora_glesfix.sh [base commit, default d1687cd]
set -euo pipefail
W="$(cd "$(dirname "$0")/.." && pwd)"
TREE=$W/work/aurora-glesfix; BASE=${1:-d1687cd}
OUT=$W/patches/aurora-glesfix
rm -rf "$OUT"; mkdir -p "$OUT"
git -C "$TREE" format-patch -q --no-signature --zero-commit -N -o "$OUT" "$BASE..HEAD" > /dev/null
ls "$OUT"
