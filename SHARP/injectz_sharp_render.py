#!/usr/bin/env python3
"""
InjectZ SHARP/metal-gauss renderer helper v0.2.5
Known-good automatic stereo-window algorithm integrated with normal InjectZ output.
"""
import argparse
import math
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
import numpy as np
import torch
from PIL import Image
from scipy import ndimage

from metal_gauss.io import load_ply
from metal_gauss.render_path import (
    frame_cloud, intrinsics, world_to_camera, render_frames, write_png, fov_from_photo
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
p.add_argument("--wiggle-frames", type=int, default=0, help="Number of intermediate views between the two eyes")
p.add_argument("--wiggle-fps", type=int, default=24)
p.add_argument("--wiggle-border", type=float, default=0)
p.add_argument("--wiggle-corners", type=float, default=0)
a = p.parse_args()
if not 0.5 <= a.edge_soften_radius <= 6 or not 0 <= a.edge_soften_strength <= 1:
    p.error("Edge radius must be 0.5–6 pixels and strength must be 0–1.")
if not 0 <= a.wiggle_frames <= 60 or not 1 <= a.wiggle_fps <= 60:
    p.error("Intermediate frames must be 0–60 and playback speed 1–60 fps.")

PHOTO = a.photo.expanduser().resolve()
PLY = a.ply.expanduser().resolve()
OUTDIR = a.output_dir.expanduser().resolve()
OUTDIR.mkdir(parents=True, exist_ok=True)

if not PHOTO.exists():
    raise SystemExit(f"Photo not found: {PHOTO}")
if not PLY.exists():
    raise SystemExit(f"SHARP PLY not found: {PLY}")

BASELINE = a.baseline

# Apple's SHARP loader applies EXIF rotations 3, 6 and 8 before prediction.
# Rotations 6/8 exchange the axes. Use the same upright dimensions when
# rendering, and use a horizontal FOV for those dimensions below.
with Image.open(PHOTO) as im:
    raw_w, raw_h = im.size
    orientation = im.getexif().get(274, 1)
    src_w, src_h = (raw_h, raw_w) if orientation in (6, 8) else (raw_w, raw_h)

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


# metal-gauss computes horizontal FOV from stored pixel dimensions. For an
# EXIF-rotated image retain the same focal length in pixels but derive the FOV
# using the upright width, matching the dimensions SHARP predicted from.
requested_fov = None
if orientation in (6, 8):
    raw_fov, focal_35mm = fov_from_photo(str(PHOTO))
    focal_px = raw_w / (2.0 * math.tan(math.radians(raw_fov) / 2.0))
    requested_fov = math.degrees(2.0 * math.atan(src_w / (2.0 * focal_px)))
    print(f"EXIF orientation {orientation}: {raw_w}x{raw_h} -> {src_w}x{src_h}; "
          f"focal length {focal_35mm:g}mm, upright horizontal FOV {requested_fov:.2f}°", flush=True)

frame_mode, fov, eye, target = frame_cloud(
    means_cpu,
    frame="input",
    up="-y",
    convention="opencv",
    fov=requested_fov,
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
    # Render within the input camera's field of view. Moving the principal
    # point exposes extrapolated splats beyond that field and can produce
    # large blurred or white strips at the image edges.
    K_left = K
    K_right = K

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

original_w = W
crop_shift = 0
if not a.allow_window_violations:
    # A whole-pixel shift avoids resampling. Rounding up retains at least the
    # requested stereo-window margin. The two crops are the common overlap
    # of the shifted views, so neither eye contains extrapolated edge pixels.
    crop_shift = math.ceil(per_eye_shift)
    if crop_shift < 0 or 2 * crop_shift >= W:
        raise RuntimeError("Stereo-window protection would crop the entire image. "
                           "Reduce the stereo baseline or allow window violations.")
    if crop_shift:
        old_left, old_right = left_img, right_img
        left_img = old_left.crop((2 * crop_shift, 0, W, H))
        right_img = old_right.crop((0, 0, W - 2 * crop_shift, H))
        old_left.close(); old_right.close()
        W -= 2 * crop_shift
        left_img.save(left_path); right_img.save(right_path)
        print(f"Stereo-window overlap crop: {crop_shift}px from each side; "
              f"remaining eye width {W}px", flush=True)

if a.wiggle_frames:
    # One reconstruction, evenly spaced virtual cameras, and a return journey
    # without repeated endpoints. Output is a normal 2D MP4 parallax animation.
    sys.path.insert(0, str(Path.home() / 'InjectZ/Development/Reframe'))
    from SharedStereoFormats import finish_eye
    try:
        import imageio_ffmpeg
        ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        raise RuntimeError('MP4 export needs FFmpeg; install it or repair the InjectZ runtime.')
    video_path = OUTDIR / f"{PHOTO.stem}_InjectZ_SHARP_Wiggle_Baseline{BASELINE:.3f}.mp4"
    with tempfile.TemporaryDirectory(prefix='injectz-wiggle-', dir=OUTDIR) as tmp:
        folder = Path(tmp)
        total = a.wiggle_frames + 2
        for i in range(total):
            if i == 0:
                frame = left_img.copy()
            elif i == total - 1:
                frame = right_img.copy()
            else:
                t = i / (total - 1)
                center = torch.tensor([(t - .5) * BASELINE, 0., 0.], dtype=torch.float32)
                view = world_to_camera(R, center)
                rgb = next(render_frames_with_scene_distance(sp, [view], K, original_w, H,
                                                              background=(1.,1.,1.), backend='metal'))
                temp_path = folder / 'render.png'
                write_png(rgb, temp_path, original_w, H)
                with Image.open(temp_path) as im:
                    frame = im.convert('RGB')
                if a.soften_depth_edges and a.edge_soften_strength > 0:
                    mask = projected_mask(sp, view, K, original_w, H, BASELINE, injectz_far_clip, a.edge_soften_radius)
                    softened = soften(frame, mask, a.edge_soften_radius, a.edge_soften_strength)
                    frame.close(); frame = softened
                if crop_shift:
                    x = round(2 * crop_shift * (1 - t))
                    cropped = frame.crop((x, 0, x + W, H))
                    frame.close(); frame = cropped
            finished = finish_eye(frame, a.wiggle_border, a.wiggle_corners)
            finished.save(folder / f'view_{i:04d}.png')
            if finished is not frame: finished.close()
            frame.close()
            print(f'Wiggle view {i + 1}/{total}', flush=True)
        order = list(range(total)) + list(range(total - 2, 0, -1))
        for i, source_index in enumerate(order):
            os.link(folder / f'view_{source_index:04d}.png', folder / f'frame_{i:04d}.png')
        command = [str(ffmpeg), '-y', '-loglevel', 'error', '-stream_loop', '4',
                   '-framerate', str(a.wiggle_fps), '-i', str(folder / 'frame_%04d.png'),
                   '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2', '-c:v', 'libx264',
                   '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(video_path)]
        subprocess.run(command, check=True)
    print(f'Wiggle animation: {video_path}', flush=True)

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
