#!/usr/bin/env python3
"""Markdown table of Vulkan vs GLES statistics per scenario.
Usage: report.py <vk cap dir> <gles cap dir> scenario=frame,frame ... [scenario=...]
Prints one row per frame: PSNR (dB), max diff, % pixels > 2, % pixels > 16."""
import sys, os
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from diff import load, stats

a, b = sys.argv[1], sys.argv[2]
print("| Scenario | Frame | PSNR dB | Max | % > 2 | % > 16 |\n|---|---|---|---|---|---|")
for spec in sys.argv[3:]:
    name, frames = spec.split("=")
    for f in frames.split(","):
        n = "f%06d.png" % int(f)
        pa, pb = os.path.join(a, n), os.path.join(b, n)
        if not (os.path.exists(pa) and os.path.exists(pb)):
            continue
        s = stats(load(pa), load(pb))
        print("| %s | %s | %s | %s | %s | %s |" % (name, f, s["psnr"], s["max"], s["gt2"], s["gt16"]))
