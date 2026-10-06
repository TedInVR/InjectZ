"""Shared LaMa background, with foreground protected by separate compositing.

LaMa TorchScript input convention follows enesmsahin/simple-lama-inpainting.
No foreground pixels are taken from the generated background.
"""
import hashlib
import json
import os
import uuid
from pathlib import Path
from urllib.request import urlopen
import numpy as np
from PIL import Image
from scipy.ndimage import binary_dilation, shift

MODEL_URL = 'https://github.com/enesmsahin/simple-lama-inpainting/releases/download/v0.1.0/big-lama.pt'

def model_path(root):
    import torch
    folder = Path(root) / 'Models' / 'LaMa'
    folder.mkdir(parents=True, exist_ok=True)
    dest = folder / 'big-lama.pt'
    if dest.exists():
        return dest
    temp = folder / ('download-' + str(uuid.uuid4()) + '.part')
    print('Downloading LaMa background repair model (first use only)…', flush=True)
    try:
        with urlopen(MODEL_URL, timeout=60) as response, temp.open('xb') as out:
            total = 0
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                out.write(chunk)
                total += len(chunk)
                if total % (20 * 1024 * 1024) == 0:
                    print('Downloaded', total // (1024 * 1024), 'MiB', flush=True)
        # Load before publishing, so interrupted/invalid downloads aren't reused.
        torch.jit.load(str(temp), map_location='cpu')
        os.replace(temp, dest)
        digest = hashlib.sha256(dest.read_bytes()).hexdigest()
        (folder / 'download.json').write_text(json.dumps({'url': MODEL_URL, 'sha256_observed': digest}, indent=2))
    finally:
        temp.unlink(missing_ok=True)
    return dest

def preserve_known(source, generated, hole):
    result = source.copy()
    result[hole] = generated[hole]
    return result

def build_background(source_path, sky_mask_path, output_path, root):
    import torch
    with Image.open(source_path) as image:
        source = np.asarray(image.convert('RGB')).copy()
    h, w = source.shape[:2]
    with Image.open(sky_mask_path) as image:
        sky = np.asarray(image.convert('L').resize((w, h), Image.Resampling.NEAREST)) > 127
    fraction = sky.mean()
    if not .02 < fraction < .98:
        raise ValueError('Repair needs a sky/background selection and an unselected foreground. Check the green highlight.')
    # Hide the foreground and its color fringe from the background model.
    hole = binary_dilation(~sky, iterations=max(2, round(min(w, h) * .003)))
    # Bounded CPU inference. Existing known sky remains full-resolution/exact.
    scale = min(1., 1024 / max(w, h))
    sw, sh = max(8, round(w * scale)), max(8, round(h * scale))
    small = np.asarray(Image.fromarray(source).resize((sw, sh), Image.Resampling.LANCZOS)).astype(np.float32) / 255.
    small_hole = np.asarray(Image.fromarray(hole.astype(np.uint8)*255).resize((sw, sh), Image.Resampling.NEAREST)) > 0
    ph, pw = (-sh) % 8, (-sw) % 8
    small = np.pad(small, ((0, ph), (0, pw), (0, 0)), mode='symmetric')
    small_hole = np.pad(small_hole, ((0, ph), (0, pw)), mode='symmetric')
    image_tensor = torch.from_numpy(small.transpose(2, 0, 1).copy())[None]
    mask_tensor = torch.from_numpy(small_hole.astype(np.float32))[None, None]
    model = torch.jit.load(str(model_path(root)), map_location='cpu').eval()
    print('Reconstructing one shared hidden background on CPU…', flush=True)
    with torch.inference_mode():
        result = model(image_tensor, mask_tensor)
    if not torch.is_tensor(result) or tuple(result.shape) != tuple(image_tensor.shape):
        raise RuntimeError('Unexpected LaMa output shape; no stereo output saved.')
    generated = result[0, :, :sh, :sw].permute(1, 2, 0).cpu().numpy()
    if not np.isfinite(generated).all():
        raise RuntimeError('Background model produced invalid pixels.')
    generated = (np.clip(generated, 0, 1)*255).round().astype(np.uint8)
    generated = np.asarray(Image.fromarray(generated).resize((w, h), Image.Resampling.LANCZOS))
    Image.fromarray(preserve_known(source, generated, hole)).save(output_path)
    Image.fromarray(hole.astype(np.uint8)*255).save(Path(output_path).with_name('background-hole.png'))

def warp_background(background, fx, source_cx, target_cx, camera_x, depth):
    if not np.isfinite(depth) or depth <= 0:
        raise ValueError('Invalid shared background depth.')
    offset = -fx * camera_x / depth + target_cx - source_cx
    # One shared texture, not two independent AI guesses. Edge extension only
    # affects the image boundary; interior exposed holes use LaMa pixels.
    return shift(background, (0, offset, 0), order=1, mode='nearest', prefilter=False)

def composite(foreground, alpha, background):
    if alpha.ndim == 3 and alpha.shape[-1] == 1:
        alpha = alpha[..., 0]
    if foreground.shape != background.shape or alpha.shape != foreground.shape[:2]:
        raise ValueError('Unexpected foreground/alpha dimensions.')
    return np.clip(foreground + (1-np.clip(alpha, 0, 1))[..., None]*background, 0, 1)
