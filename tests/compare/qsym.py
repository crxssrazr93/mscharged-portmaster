#!/usr/bin/env python3
"""Symbolize and compare the CAPTURE_TRACE=2 clock query traces of two runs.
Usage: qsym.py <run dir A> <run dir B>   (run dirs contain cap/trace.txt and cap/maps.txt)"""
import sys, subprocess, re, os, collections
def maps(d):
    rows = []
    for l in open(os.path.join(d, "cap/maps.txt")):
        p = l.split()
        if len(p) >= 6 and "x" in p[1]:
            a, b = [int(x, 16) for x in p[0].split("-")]
            rows.append((a, b, int(p[2], 16), p[5]))
    return rows
cache = {}
def sym(rows, v):
    for a, b, off, path in rows:
        if a <= v < b:
            key = (path, v - a + off)
            if key not in cache:
                r = subprocess.run(["addr2line", "-f", "-C", "-e", path, hex(v - a + off)], capture_output=True, text=True).stdout.split("\n")[0]
                cache[key] = f"{os.path.basename(path)}:{r}"
            return cache[key]
    return hex(v)
def frames(d):
    rows = maps(d); out = []
    for l in open(os.path.join(d, "cap/trace.txt")):
        if not l.startswith("Q"): continue
        c = collections.Counter()
        for tok in l[1:].split():
            addrs, n = tok.split(":")
            c["<".join(sym(rows, int(x, 16)) for x in addrs.split(",")[1:3])] += int(n)
        out.append(c)
    return out
A, B = frames(sys.argv[1]), frames(sys.argv[2])
for i, (x, y) in enumerate(zip(A, B)):
    if x != y:
        print("frame", i)
        for k in sorted(set(x) | set(y)):
            if x[k] != y[k]: print("   ", x[k], y[k], k)
