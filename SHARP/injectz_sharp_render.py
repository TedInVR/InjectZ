#!/usr/bin/env python3
"""
InjectZ SHARP/metal-gauss renderer helper v0.2.5
Known-good automatic stereo-window algorithm integrated with normal InjectZ output.
"""
import argparse
from pathlib import Path
import numpy as np
import torch
from PIL import Image
from scipy import ndimage

from metal_gauss.io import load_ply
from metal_gauss.render_path import (
    frame_cloud, intrinsics, world_to_camera, render_frames, write_png
)

def robust_foreground_depth(sp, K, W, H):
    xyz = sp.means.detach().cpu().numpy()
    op = sp.opacities.detach().cpu().numpy().reshape(-1)
    if np.nanmin(op) < 0 or np.nanmax(op) > 1:
        op = 1.0 / (1.0 + np.exp(-op))

    fx, fy = float(K[0,0]), float(K[1,1])
    cx, cy = float(K[0,2]), float(K[1,2])
    x, y, z = xyz[:,0], xyz[:,1], xyz[:,2]

    valid = np.isfinite(x) & np.isfinite(y) & np.isfinite(z) & (z > 0) & (op >= 0.10)
    x, y, z = x[valid], y[valid], z[valid]

    u = fx * x / z + cx
    v = fy * y / z + cy
    onscreen = (u >= 0) & (u < W) & (v >= 0) & (v < H)
    u, v, z = u[onscreen], v[onscreen], z[onscreen]

    scale = max(1, int(round(W / 500)))
    gw = (W + scale - 1) // scale
    gh = (H + scale - 1) // scale
    ix = np.clip((u / scale).astype(np.int32), 0, gw-1)
    iy = np.clip((v / scale).astype(np.int32), 0, gh-1)

    depth = np.full((gh, gw), np.inf, dtype=np.float32)
    np.minimum.at(depth, (iy, ix), z.astype(np.float32))
    finite = np.isfinite(depth)
    vals = depth[finite]
    if vals.size == 0:
        raise RuntimeError("No projected SHARP geometry found in the image.")

    candidate_percentiles = [0.1, 0.25, 0.5, 1, 2, 3, 5, 7.5, 10]
    chosen = None

    for pct in candidate_percentiles:
        threshold = np.percentile(vals, pct)
        near = finite & (depth <= threshold)
        linked = ndimage.binary_dilation(near, iterations=1)
        labels, n = ndimage.label(linked, structure=np.ones((3,3), dtype=np.uint8))

        best = None
        for lab in range(1, n+1):
            yy, xx = np.where(labels == lab)
            if len(xx) == 0:
                continue
            span_x = xx.max() - xx.min() + 1
            span_y = yy.max() - yy.min() + 1
            touches_edge = (xx.min() <= 1 or yy.min() <= 1 or
                            xx.max() >= gw-2 or yy.max() >= gh-2)

            long_structure = (span_x >= 0.08*gw or span_y >= 0.08*gh)
            enough_support = len(xx) >= max(12, int(0.00015*gw*gh))
            edge_structure = touches_edge and (
                span_x >= 0.03*gw or span_y >= 0.03*gh
            ) and len(xx) >= 6

            if (long_structure and enough_support) or edge_structure:
                original_cells = (labels == lab) & near
                zz = depth[original_cells]
                zz = zz[np.isfinite(zz)]
                if zz.size:
                    component_z = float(np.percentile(zz, 1.0))
                    score = (component_z, -max(span_x/gw, span_y/gh), -len(xx))
                    if best is None or score < best[0]:
                        best = (score, component_z, pct, span_x, span_y, len(xx))

        if best is not None:
            chosen = best
            break

    if chosen is None:
        zc = float(np.percentile(vals, 0.5))
        info = ("fallback", 0.5, 0, 0, 0)
    else:
        _, zc, pct, sx, sy, count = chosen
        info = ("coherent", pct, sx, sy, count)

    return zc, info

def shifted_K(K, delta_x):
    out = K.clone()
    out[0,2] += float(delta_x)
    return out

p = argparse.ArgumentParser()
p.add_argument("--photo", required=True, type=Path)
p.add_argument("--ply", required=True, type=Path)
p.add_argument("--baseline", required=True, type=float)
p.add_argument("--format", choices=("parallel", "crossview"), default="parallel")
p.add_argument("--eye-width", type=int, default=None,
               help="Optional per-eye width override. Default preserves source dimensions.")
p.add_argument("--output-dir", required=True, type=Path)
p.add_argument("--keep-eyes", action="store_true")
p.add_argument("--allow-window-violations", action="store_true")
p.add_argument("--margin-px", type=float, default=2.0)
p.add_argument("--soften-depth-edges", action="store_true")
p.add_argument("--edge-soften-radius", type=float, default=2.0)
p.add_argument("--edge-soften-strength", type=float, default=0.35)
a = p.parse_args()
if not 0.5 <= a.edge_soften_radius <= 6 or not 0 <= a.edge_soften_strength <= 1:
    p.error("Edge radius must be 0.5–6 pixels and strength must be 0–1.")

PHOTO = a.photo.expanduser().resolve()
PLY = a.ply.expanduser().resolve()
OUTDIR = a.output_dir.expanduser().resolve()
OUTDIR.mkdir(parents=True, exist_ok=True)

if not PHOTO.exists():
    raise SystemExit(f"Photo not found: {PHOTO}")
if not PLY.exists():
    raise SystemExit(f"SHARP PLY not found: {PLY}")

BASELINE = a.baseline

with Image.open(PHOTO) as im:
    src_w, src_h = im.size

if a.eye_width is None:
    W, H = src_w, src_h
else:
    W = a.eye_width
    H = round(W * src_h / src_w)

device = torch.device("mps")
sp = load_ply(PLY, device=device)
means_cpu = sp.means.detach().cpu()

# SHARP may place sky beyond Metal's default far=100. The distant geometry
# already exists in the PLY; do not discard it or change the reconstruction.
positive_z = means_cpu[:, 2]
positive_z = positive_z[torch.isfinite(positive_z) & (positive_z > 0)]
if positive_z.numel() == 0:
    raise RuntimeError("SHARP model has no finite positive depths.")
injectz_far_clip = max(100.0, float(positive_z.max()) * 1.1 + 1.0)
if not np.isfinite(injectz_far_clip) or injectz_far_clip > 1e25:
    raise RuntimeError("SHARP model has extreme depth values; refusing unsafe distance limit.")

def render_frames_with_scene_distance(sp, views, K, W, H, background, backend):
    from metal_gauss.api import render as render_splats
    for vm in views:
        rgb, _, _ = render_splats(
            sp.means, sp.quats, sp.scales, sp.opacities, sp.sh,
            K, vm, W, H, sh_degree=sp.sh_degree, backend=backend,
            background=background, far=injectz_far_clip,
        )
        yield rgb.detach().clamp(0.0, 1.0)
print(f"SHARP scene-aware far clipping distance: {injectz_far_clip:.4f}", flush=True)


frame_mode, fov, eye, target = frame_cloud(
    means_cpu,
    frame="input",
    up="-y",
    convention="opencv",
    fov=None,
    like_photo=str(PHOTO),
    depth=None,
    opacities=sp.opacities.detach().cpu(),
)

K = intrinsics(W, H, fov)

if a.allow_window_violations:
    K_left = K
    K_right = K
    zc = None
    info = None
    foreground_disparity = None
    per_eye_shift = 0.0
else:
    zc, info = robust_foreground_depth(sp, K, W, H)
    fx = float(K[0,0])
    foreground_disparity = fx * BASELINE / zc
    per_eye_shift = (foreground_disparity + a.margin_px) / 2.0
    K_left = shifted_K(K, -per_eye_shift)
    K_right = shifted_K(K, per_eye_shift)

R = torch.eye(3)
left_center = torch.tensor([-BASELINE / 2.0, 0.0, 0.0], dtype=torch.float32)
right_center = torch.tensor([BASELINE / 2.0, 0.0, 0.0], dtype=torch.float32)
left_view = world_to_camera(R, left_center)
right_view = world_to_camera(R, right_center)

left = list(render_frames_with_scene_distance(
    sp, [left_view], K_left, W, H,
    background=(1.0,1.0,1.0), backend="metal"
))[0]
right = list(render_frames_with_scene_distance(
    sp, [right_view], K_right, W, H,
    background=(1.0,1.0,1.0), backend="metal"
))[0]

token = f"{BASELINE:.3f}"
left_path = OUTDIR / f"{PHOTO.stem}_Left_InjectZ_SHARP_Baseline{token}.png"
right_path = OUTDIR / f"{PHOTO.stem}_Right_InjectZ_SHARP_Baseline{token}.png"

write_png(left, left_path, W, H)
write_png(right, right_path, W, H)

left_img = Image.open(left_path).convert("RGB")
right_img = Image.open(right_path).convert("RGB")
if a.soften_depth_edges and a.edge_soften_strength > 0:
    from EdgeSoftener import projected_mask, soften
    print("Softening SHARP depth boundaries independently in each eye…", flush=True)
    left_mask = projected_mask(sp, left_view, K_left, W, H, BASELINE, injectz_far_clip, a.edge_soften_radius)
    right_mask = projected_mask(sp, right_view, K_right, W, H, BASELINE, injectz_far_clip, a.edge_soften_radius)
    left_soft = soften(left_img, left_mask, a.edge_soften_radius, a.edge_soften_strength)
    right_soft = soften(right_img, right_mask, a.edge_soften_radius, a.edge_soften_strength)
    left_img.close(); right_img.close()
    left_img, right_img = left_soft, right_soft
    left_img.save(left_path); right_img.save(right_path)
    print(f"Edge radius {a.edge_soften_radius:.2f}px; strength {a.edge_soften_strength:.0%}; "
          f"affected masks L {np.mean(left_mask > 0):.2%}, R {np.mean(right_mask > 0):.2%}", flush=True)

label = "Parallel" if a.format == "parallel" else "Crossview"
sbs_path = OUTDIR / f"{PHOTO.stem}_{label}_InjectZ_SHARP_Baseline{token}.png"

sbs = Image.new("RGB", (W * 2, H))
if a.format == "parallel":
    sbs.paste(left_img, (0,0))
    sbs.paste(right_img, (W,0))
else:
    sbs.paste(right_img, (0,0))
    sbs.paste(left_img, (W,0))
sbs.save(sbs_path)

left_img.close()
right_img.close()

if not a.keep_eyes:
    left_path.unlink(missing_ok=True)
    right_path.unlink(missing_ok=True)

print()
print("InjectZ SHARP stereo render complete")
print(f"Photo: {PHOTO.name}")
print(f"PLY: {PLY.name}")
print(f"Source: {src_w} x {src_h}")
print(f"Each eye: {W} x {H}")
print(f"{label} SBS: {W*2} x {H}")
print(f"Subject depth: {float(target[2]):.4f}")
print(f"Stereo baseline: {BASELINE:.4f}")
if a.allow_window_violations:
    print("Automatic stereo-window protection: OFF (window violations allowed)")
else:
    mode, pct, sx, sy, count = info
    print("Automatic stereo-window protection: ON")
    print(f"Detected foreground Z: {zc:.6f}")
    print(f"Detection: {mode} (near-set percentile {pct}%)")
    if mode == "coherent":
        print(f"Detected component: span {sx} x {sy} coarse cells; support {count}")
    print(f"Foreground raw disparity: {foreground_disparity:.2f}px")
    print(f"Per-eye convergence shift: {per_eye_shift:.2f}px")
    print(f"Safety margin behind window: {a.margin_px:.2f}px")
print(f"Output: {sbs_path}")
