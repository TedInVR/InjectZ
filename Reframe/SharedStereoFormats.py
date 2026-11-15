#!/usr/bin/env python3
"""Generate requested stereo photographs from one full-size Parallel SBS render.
Dubois matrices and sRGB transfer follow Eric Dubois (2009),
https://www.site.uottawa.ca/~edubois/anaglyph/LeastSquaresHowToPhotoshop.pdf
"""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps, ImageDraw

FORMATS = ('Parallel', 'Crossview', 'Anaglyph_FullColor', 'Anaglyph_HalfColor', 'Anaglyph_Dubois', 'Left_Right_Left', 'Parallel_Over_Crossview')
DUBOIS_LEFT = np.array([[.437,.449,.164],[-.062,-.062,-.024],[-.048,-.050,-.017]], dtype=np.float32)
DUBOIS_RIGHT = np.array([[-.011,-.032,-.007],[.377,.761,.009],[-.026,-.093,1.234]], dtype=np.float32)

def srgb_to_linear(x):
    return np.where(x <= .04045, x / 12.92, ((x + .055) / 1.055) ** 2.4)

def linear_to_srgb(x):
    return np.where(x <= .0031308, x * 12.92, 1.055 * np.maximum(x, 0) ** (1 / 2.4) - .055)

def output_image(left, right, fmt):
    if fmt == 'Left_Right_Left':
        out = Image.new('RGB', (left.width * 3, left.height))
        for i, eye in enumerate((left, right, left)):
            out.paste(eye, (i * left.width, 0))
        return out
    if fmt == 'Parallel_Over_Crossview':
        out = Image.new('RGB', (left.width * 2, left.height * 2))
        for x, y, eye in ((0, 0, left), (left.width, 0, right),
                          (0, left.height, right), (left.width, left.height, left)):
            out.paste(eye, (x, y))
        return out
    if fmt in ('Parallel', 'Crossview'):
        first, second = (left, right) if fmt == 'Parallel' else (right, left)
        out = Image.new('RGB', (left.width * 2, left.height))
        out.paste(first, (0, 0)); out.paste(second, (left.width, 0))
        return out
    l = np.asarray(left, dtype=np.float32) / 255
    r = np.asarray(right, dtype=np.float32) / 255
    if fmt == 'Anaglyph_FullColor':
        a = np.stack((l[:,:,0], r[:,:,1], r[:,:,2]), axis=2)
    elif fmt == 'Anaglyph_HalfColor':
        red = .299*l[:,:,0] + .587*l[:,:,1] + .114*l[:,:,2]
        a = np.stack((red, r[:,:,1], r[:,:,2]), axis=2)
    else:
        ll, rr = srgb_to_linear(l), srgb_to_linear(r)
        a = linear_to_srgb(np.clip(ll @ DUBOIS_LEFT.T + rr @ DUBOIS_RIGHT.T, 0, 1))
    return Image.fromarray(np.uint8(np.clip(a, 0, 1) * 255 + .5), 'RGB')

def finish_eye(image, border_percent, corner_percent):
    """Apply identical black framing per eye after stereo generation."""
    w, h = image.size
    scale = min(w, h)
    radius = round(scale * corner_percent / 100)
    if radius:
        factor = 4
        mask = Image.new('L', (w * factor, h * factor), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, w * factor - 1, h * factor - 1),
            radius=radius * factor, fill=255)
        mask = mask.resize((w, h), Image.Resampling.LANCZOS)
        image = Image.composite(image, Image.new('RGB', (w, h), 'black'), mask)
    padding = round(scale * border_percent / 100)
    return ImageOps.expand(image, border=padding, fill='black') if padding else image

def main():
    p = argparse.ArgumentParser()
    p.add_argument('parallel_sbs', type=Path)
    p.add_argument('--output-prefix', type=Path, required=True)
    p.add_argument('--depth-token', required=True)
    p.add_argument('--formats', nargs='+', choices=FORMATS, required=True)
    p.add_argument('--retain-source', action='store_true')
    p.add_argument('--border-percent', type=float, default=0, choices=(0, 1, 2, 5, 10))
    p.add_argument('--corner-percent', type=float, default=0, choices=(0, 2, 5, 10, 20))
    a = p.parse_args()
    with Image.open(a.parallel_sbs) as image:
        image.load()
        if image.width % 2: p.error('Full SBS width must be even.')
        w = image.width // 2
        left = image.crop((0, 0, w, image.height)).convert('RGB')
        right = image.crop((w, 0, image.width, image.height)).convert('RGB')
    left = finish_eye(left, a.border_percent, a.corner_percent)
    right = finish_eye(right, a.border_percent, a.corner_percent)
    for fmt in dict.fromkeys(a.formats):
        name = a.output_prefix.with_name(a.output_prefix.name + '_' + fmt + '_Depth' + a.depth_token)
        dest = Path(str(name) + '.png'); i = 2
        while dest.exists() or dest == a.parallel_sbs:
            dest = Path(str(name) + f'_{i}.png'); i += 1
        output_image(left, right, fmt).save(dest)
        print('SUCCESS', dest, flush=True)
    if not a.retain_source:
        # Source is a dedicated temporary render; never delete arbitrary input files.
        pass

if __name__ == '__main__': main()
