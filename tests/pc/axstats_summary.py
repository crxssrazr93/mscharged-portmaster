#!/usr/bin/env python3
"""Summarise the [axstats] lines of a game.log (MSCHARGED_AXSTATS=1 run): totals and per AX frame averages."""
import re, sys
keys = ["ax_frames", "ax_ms", "voices", "active", "decoded", "read_calls", "read_bytes", "sample_calls", "sample_bytes",
        "write_calls", "write_bytes", "bind_ms", "list_ms", "prepare_ms", "commit_ms", "validate_calls", "p2c_calls",
        "c2p_calls", "poll_calls"]
for path in sys.argv[1:]:
    tot = {k: 0.0 for k in keys}; lines = 0; worst = 0.0; last_hash = ""; ref = 0
    for line in open(path, errors="replace"):
        if not line.startswith("[axstats]"): continue
        kv = dict(re.findall(r"(\w+)=([0-9.a-f]+)", line))
        if float(kv.get("ax_frames", 0)) < 50: continue          # skip the near idle seconds (loading)
        lines += 1
        for k in keys: tot[k] += float(kv.get(k, 0))
        worst = max(worst, float(kv["us_per_frame"]))
        last_hash = kv.get("frame_hash", ""); ref = max(ref, int(float(kv.get("ref_frames_total", 0))))
    f = tot["ax_frames"] or 1
    print(f"== {path}: {lines} s with AX load, {int(f)} AX frames, worst second {worst:.0f} us/frame, ref_frames_checked {ref}")
    print(f"   cpu us per AX frame     {tot['ax_ms'] * 1000 / f:9.1f}   (bind {tot['bind_ms'] * 1000 / f:.1f}, prepare {tot['prepare_ms'] * 1000 / f:.1f}, commit {tot['commit_ms'] * 1000 / f:.1f})")
    for k in ["voices", "active", "decoded", "read_calls", "read_bytes", "sample_calls", "sample_bytes", "write_calls", "validate_calls", "p2c_calls", "c2p_calls", "poll_calls"]:
        print(f"   {k:<15} per AX frame {tot[k] / f:12.1f}")
