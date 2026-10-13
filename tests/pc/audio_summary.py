#!/usr/bin/env python3
"""Summarise the [audiostats] lines of game logs: totals over the seconds from FROM on (default 25, after the quiet start)."""
import re, sys
start = int(sys.argv[1]) if sys.argv[1:] and sys.argv[1].isdigit() else 25
for path in sys.argv[1:]:
    if path.isdigit(): continue
    rows = []
    for line in open(path, errors="replace"):
        if line.startswith("[audiostats]"):
            row = dict(re.findall(r"(\w+)=([-0-9.a-f]+)", line))
            row["qavg"] = re.search(r"queue_ms min=\S+ avg=(\S+)", line).group(1)
            rows.append(row)
    rows = rows[start:]
    if not rows: print(path, "no data"); continue
    def tot(k): return sum(float(r.get(k, 0)) for r in rows)
    print(f"== {path}: {len(rows)} s from second {start}")
    print(f"   underruns {int(tot('underruns'))}  silence_ms {tot('silence_ms'):.0f}  seconds with an underrun {sum(1 for r in rows if float(r['underruns'])>0)}"
          f"  queue_ms avg {sum(float(r['qavg']) for r in rows)/len(rows):.1f}")
    print(f"   blocks/s {tot('blocks')/len(rows):.0f}  skipped_blocks {tot('skipped_blocks'):.0f}  replayed {int(tot('replayed'))}  dup {int(tot('dup'))}"
          f"  svc_periods {int(tot('svc_periods'))} svc_bursts {int(tot('svc_bursts'))} pace_timeouts {int(tot('pace_timeouts'))}")
