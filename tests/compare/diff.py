#!/usr/bin/env python3
"""Compare two capture directories frame by frame.
Usage: diff.py <dir A> <dir B> [--out DIR] [--label A B]
Prints per frame: PSNR, max diff, % pixels differing by more than 2 and more than 16, mean abs diff.
With --out writes side by side (A | B | amplified diff) PNGs and a summary JSON/histogram."""
import sys, os, json, argparse
import numpy as np
from PIL import Image

def load(p):
    return np.asarray(Image.open(p).convert("RGB"), dtype=np.int16)

def stats(a, b):
    if a.shape != b.shape:
        return dict(shape=f"{a.shape} vs {b.shape}")
    d = np.abs(a - b)
    mx = int(d.max())
    mse = float((d.astype(np.float64) ** 2).mean())
    psnr = 99.0 if mse == 0 else 10 * np.log10(255.0 ** 2 / mse)
    px = d.max(axis=2)
    return dict(psnr=round(float(psnr), 2), max=mx, gt2=round(float((px > 2).mean() * 100), 3),
                gt16=round(float((px > 16).mean() * 100), 3), mad=round(float(d.mean()), 4),
                identical=bool(mx == 0))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("a"); ap.add_argument("b"); ap.add_argument("--out")
    ap.add_argument("--amp", type=int, default=8)
    args = ap.parse_args()
    names = sorted(f for f in os.listdir(args.a) if f.endswith(".png") and os.path.exists(os.path.join(args.b, f)))
    rows = {}
    hist = np.zeros(256, dtype=np.int64)
    for f in names:
        a, b = load(os.path.join(args.a, f)), load(os.path.join(args.b, f))
        s = stats(a, b); rows[f] = s
        if "max" in s:
            hist += np.bincount(np.abs(a - b).max(axis=2).ravel(), minlength=256)
            if args.out:
                os.makedirs(args.out, exist_ok=True)
                d = np.clip(np.abs(a - b).max(axis=2) * args.amp, 0, 255).astype(np.uint8)
                dimg = np.stack([d, d, d], axis=2)
                side = np.concatenate([a.astype(np.uint8), b.astype(np.uint8), dimg], axis=1)
                Image.fromarray(side).save(os.path.join(args.out, f))
        print(f, s)
    ident = sum(1 for s in rows.values() if s.get("identical"))
    print(f"frames compared {len(rows)}, bit identical {ident}")
    if args.out:
        json.dump(dict(frames=rows, hist=hist.tolist()), open(os.path.join(args.out, "summary.json"), "w"))

if __name__ == "__main__":
    main()
