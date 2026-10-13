#!/usr/bin/env python3
"""Contact sheet of captured frames. Usage: montage.py <cap dir> <out.png> [first last step] [cols] [scale]"""
import sys, os
from PIL import Image, ImageDraw
d, out = sys.argv[1], sys.argv[2]
a = [int(x) for x in sys.argv[3:6]] if len(sys.argv) > 5 else None
cols = int(sys.argv[6]) if len(sys.argv) > 6 else 4
scale = float(sys.argv[7]) if len(sys.argv) > 7 else 0.4
files = sorted(f for f in os.listdir(d) if f.endswith(".png"))
if a: files = [f for f in files if a[0] <= int(f[1:7]) <= a[1] and (int(f[1:7]) - a[0]) % a[2] == 0]
ims = []
for f in files:
    im = Image.open(os.path.join(d, f)).convert("RGB"); im = im.resize((int(im.width * scale), int(im.height * scale)))
    ImageDraw.Draw(im).text((4, 4), f[1:7], fill=(255, 255, 0)); ims.append(im)
if not ims: sys.exit("no frames")
w, h = ims[0].size; rows = (len(ims) + cols - 1) // cols
sheet = Image.new("RGB", (w * cols, h * rows))
for i, im in enumerate(ims): sheet.paste(im, ((i % cols) * w, (i // cols) * h))
sheet.save(out)
