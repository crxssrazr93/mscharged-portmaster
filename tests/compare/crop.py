#!/usr/bin/env python3
"""Crop and upscale regions: crop.py out.png x y w h scale img1 [img2 ...] (images side by side)."""
import sys
from PIL import Image
out, x, y, w, h, s = sys.argv[1], *map(int, sys.argv[2:6]), float(sys.argv[6])
ims = [Image.open(p).convert("RGB").crop((x, y, x + w, y + h)) for p in sys.argv[7:]]
ims = [i.resize((int(w * s), int(h * s)), Image.NEAREST) for i in ims]
sheet = Image.new("RGB", (sum(i.width for i in ims) + 4 * (len(ims) - 1), ims[0].height), (255, 0, 255))
o = 0
for i in ims: sheet.paste(i, (o, 0)); o += i.width + 4
sheet.save(out)
