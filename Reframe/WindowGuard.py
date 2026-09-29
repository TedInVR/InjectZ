#!/usr/bin/env python3
"""Estimate a safe stereo-window convergence from corresponding border details."""
import math

import numpy as np
from PIL import Image


def convergence_pixels(left: Image.Image, right: Image.Image, pan: float) -> int:
    if left.size != right.size:
        raise ValueError("Stereo eyes have different dimensions")
    w, h = left.size
    if w < 200 or h < 150:
        return 0
    # A conservative baseline when the border has little useful texture.
    fallback = math.ceil(w * max(0.0, pan) * 0.62)
    l = np.asarray(left.convert("L"), dtype=np.float32)
    r = np.asarray(right.convert("L"), dtype=np.float32)
    rad = 16
    max_left = min(w // 4, max(90, math.ceil(w * max(0.0, pan) * 3)))
    max_right = max(20, math.ceil(w * max(0.0, pan) * 0.4))
    matches = []
    # A foreground subject cut by either edge can violate the window.
    # The earlier left-only probe missed a woman crossing the RIGHT edge.
    border_x = (32, 56, 88, 120, 156, w-156, w-120, w-88, w-56, w-32)
    for x in border_x:
        if x + rad >= w: continue
        for y in range(56, h - 56, 85):
            a = l[y-rad:y+rad, x-rad:x+rad]
            a = a - a.mean()
            norm_a = float(np.linalg.norm(a))
            if norm_a < 160: continue
            best = (-1.0, 0)
            for dy in (-2, 0, 2):
                yy = y + dy
                for dx in range(-max_left, max_right + 1):
                    xx = x + dx
                    if xx - rad < 0 or xx + rad > w: continue
                    b = r[yy-rad:yy+rad, xx-rad:xx+rad]
                    b = b - b.mean()
                    denom = norm_a * float(np.linalg.norm(b))
                    if denom < 1: continue
                    score = float(np.sum(a * b)) / denom
                    if score > best[0]: best = (score, dx)
            if best[0] >= 0.88:
                matches.append(best[1])
    # Move both crop windows equally in the stereo assembly. This corrects
    # absolute placement relative to the stereo window, not relative depth.
    observed = max(0, -min(matches) + 3) if len(matches) >= 5 else 0
    return min(w // 5, max(fallback, observed))
