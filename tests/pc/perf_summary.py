#!/usr/bin/env python3
"""Mean fps and frame ms per 20 s window of a run, from the [perf] lines in <run>/game.log, and the mean of the
[gl-time] ms-per-second values (second half of the lines) from <run>/mscharged.log. Usage: perf_summary.py <run dir>"""
import re, sys
d = sys.argv[1]
fps = [float(m.group(1)) for l in open(d + "/game.log", errors="replace") for m in [re.search(r"\[perf\] fps=([\d.]+)", l)] if m]
print("fps per 20 s:", " ".join("%.1f" % (sum(fps[i:i+20]) / len(fps[i:i+20])) for i in range(0, len(fps), 20)), "| mean %.2f" % (sum(fps) / max(1, len(fps))))
rows = []
for l in open(d + "/mscharged.log", errors="replace"):
    if "[gl-time]" in l:
        rows.append({k: float(v) for k, v in re.findall(r"([a-z-]+(?: \(upload)?) \(?([\d.]+)", l.split("per second:")[1])})
if rows:
    keys = rows[0].keys()
    print("gl-time mean ms/s (%d samples):" % len(rows), " ".join("%s=%.0f" % (k, sum(r.get(k, 0) for r in rows) / len(rows)) for k in keys))
