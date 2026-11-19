"""Geometry helpers for an experimental SHARP wiggle pivot selector.

Coordinates use the un-cropped, upright reconstruction's image dimensions.
These helpers do not modify the stereo pair or synthesize missing image edges.
"""
import math

import numpy as np


def estimate_pivot_depth(means, opacities, intrinsics, width, height, x, y):
    """Estimate a clicked surface depth from nearby projected splat centers.

    x and y are normalized image coordinates, measured from the top left.
    The median depth among the nearest centers is deliberately robust to a few
    stray splats; a click at a depth boundary may still need user adjustment.
    """
    if not (0 <= x <= 1 and 0 <= y <= 1) or width <= 0 or height <= 0:
        raise ValueError('Invalid pivot coordinates or image size')
    points = np.asarray(means)
    opacity = np.asarray(opacities).reshape(-1)
    if points.ndim != 2 or points.shape[1] != 3 or len(points) != len(opacity):
        raise ValueError('Invalid splat geometry')
    if np.any((opacity < 0) | (opacity > 1)):
        opacity = 1 / (1 + np.exp(-np.clip(opacity, -80, 80)))
    z = points[:, 2]
    valid = np.isfinite(points).all(axis=1) & np.isfinite(opacity) & (z > 0) & (opacity >= .1)
    points = points[valid]
    if not len(points):
        raise ValueError('No visible SHARP geometry')
    z = points[:, 2]
    u = intrinsics[0, 0] * points[:, 0] / z + intrinsics[0, 2]
    v = intrinsics[1, 1] * points[:, 1] / z + intrinsics[1, 2]
    d2 = (u - x * (width - 1)) ** 2 + (v - y * (height - 1)) ** 2
    radius = max(3.0, min(width, height) * .01)
    nearby = np.flatnonzero(d2 <= radius * radius)
    if len(nearby) == 0:
        raise ValueError('No SHARP geometry near the selected point')
    nearest = nearby[np.argsort(d2[nearby])[:64]]
    return float(np.median(z[nearest]))


def pivot_crop_positions(focal_pixels, baseline, depth, width, frames):
    """Return same-width crop offsets that stabilize a chosen depth plane.

    The entire sequence uses its common overlap; no extrapolation or padding.
    """
    if not all(math.isfinite(v) and v > 0 for v in (focal_pixels, baseline, depth)):
        raise ValueError('Invalid pivot geometry')
    if width <= 0 or frames < 2:
        raise ValueError('Invalid sequence dimensions')
    disparity = focal_pixels * baseline / depth
    span = math.ceil(disparity)
    if span >= width:
        raise ValueError('Pivot would require cropping the entire image')
    offsets = [round(disparity * (1 - i / (frames - 1))) for i in range(frames)]
    return width - span, offsets
