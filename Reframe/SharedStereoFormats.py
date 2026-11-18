#!/usr/bin/env python3
"""Generate requested stereo photographs from one full-size Parallel SBS render.
Dubois matrices and sRGB transfer follow Eric Dubois (2009),
https://www.site.uottawa.ca/~edubois/anaglyph/LeastSquaresHowToPhotoshop.pdf
"""
import argparse
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps, ImageDraw, ImageFont, ImageColor

FORMATS = ('Parallel', 'Crossview', 'Anaglyph_FullColor', 'Anaglyph_HalfColor', 'Anaglyph_Dubois', 'Left_Right_Left', 'Parallel_Over_Crossview', 'LeftEye', 'RightEye')
DUBOIS_LEFT = np.array([[.437,.449,.164],[-.062,-.062,-.024],[-.048,-.050,-.017]], dtype=np.float32)
DUBOIS_RIGHT = np.array([[-.011,-.032,-.007],[.377,.761,.009],[-.026,-.093,1.234]], dtype=np.float32)

def srgb_to_linear(x):
    return np.where(x <= .04045, x / 12.92, ((x + .055) / 1.055) ** 2.4)

def linear_to_srgb(x):
    return np.where(x <= .0031308, x * 12.92, 1.055 * np.maximum(x, 0) ** (1 / 2.4) - .055)

def output_image(left, right, fmt):
    if fmt == 'LeftEye': return left.copy()
    if fmt == 'RightEye': return right.copy()
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

def finish_stereo_card(image, color, title=''):
    """Frame a finished camera view; never alter the source sent to SHARP."""
    rgb = ImageColor.getrgb(color)
    if len(rgb) != 3:
        raise ValueError('Card background must be an opaque color.')
    image = image.convert('RGB')
    w, h = image.size
    unit = min(w, h)
    border = max(2, round(unit * .025))
    title = ' '.join(title.split())
    bottom = max(border, round(unit * (.15 if title else .075)))
    # Even dimensions avoid an encoder adding a black stripe to colored cards.
    canvas_w, canvas_h = w + 2 * border, h + border + bottom
    canvas_w += canvas_w % 2; canvas_h += canvas_h % 2
    canvas = Image.new('RGB', (canvas_w, canvas_h), rgb)
    # Large, symmetric top arches and independently small bottom corners.
    mask = Image.new('L', (w, h), 0)
    draw = ImageDraw.Draw(mask)
    top = max(1, min(round(w * .36), h // 2))
    foot = max(1, round(unit * .025))
    draw.rectangle((0, top, w-1, h-foot-1), fill=255)
    draw.rounded_rectangle((0, max(top, h-2*foot-1), w-1, h-1), radius=foot, fill=255)
    draw.rectangle((top, 0, w-top-1, top), fill=255)
    draw.pieslice((0, 0, 2*top, 2*top), 180, 270, fill=255)
    draw.pieslice((w-1-2*top, 0, w-1, 2*top), 270, 360, fill=255)
    canvas.paste(image, (border, border), mask)
    if title:
        painter = ImageDraw.Draw(canvas)
        size = max(8, round(bottom * .38))
        font = None
        for path in ('/System/Library/Fonts/Supplemental/Arial.ttf',
                     '/System/Library/Fonts/Helvetica.ttc', 'DejaVuSans.ttf'):
            try: font = ImageFont.truetype(path, size); break
            except OSError: continue
        if font is None: font = ImageFont.load_default()
        # Shrink long captions to keep them within the card.
        while size > 8:
            bounds = painter.textbbox((0, 0), title, font=font)
            if bounds[2] - bounds[0] <= canvas_w - 4*border: break
            size -= 1
            try: font = ImageFont.truetype(path, size)
            except OSError: break
        bounds = painter.textbbox((0, 0), title, font=font)
        tw, th = bounds[2]-bounds[0], bounds[3]-bounds[1]
        brightness = .299*rgb[0] + .587*rgb[1] + .114*rgb[2]
        ink = (0,0,0) if brightness >= 140 else (255,255,255)
        painter.text(((canvas_w-tw)//2-bounds[0], border+h+(bottom-th)//2-bounds[1]),
                     title, font=font, fill=ink)
    return canvas

def main():
    p = argparse.ArgumentParser()
    p.add_argument('parallel_sbs', type=Path)
    p.add_argument('--output-prefix', type=Path, required=True)
    p.add_argument('--depth-token', required=True)
    p.add_argument('--formats', nargs='+', choices=FORMATS, required=True)
    p.add_argument('--retain-source', action='store_true')
    p.add_argument('--border-percent', type=float, default=0, choices=(0, 1, 2, 5, 10))
    p.add_argument('--corner-percent', type=float, default=0, choices=(0, 2, 5, 10, 20))
    p.add_argument('--input-format', choices=('parallel', 'crossview', 'eyes'), default='parallel')
    p.add_argument('--right-eye', type=Path)
    a = p.parse_args()
    with Image.open(a.parallel_sbs) as image:
        image = ImageOps.exif_transpose(image).convert('RGB')
        if a.input_format == 'eyes':
            if not a.right_eye: p.error('Separate eye input requires --right-eye.')
            left = image.copy()
            with Image.open(a.right_eye) as second:
                right = ImageOps.exif_transpose(second).convert('RGB')
            if left.size != right.size: p.error('The separate left and right images must have identical dimensions.')
        else:
            if image.width % 2: p.error('Full SBS width must be even.')
            w = image.width // 2
            first = image.crop((0, 0, w, image.height))
            second = image.crop((w, 0, image.width, image.height))
            left, right = (first, second) if a.input_format == 'parallel' else (second, first)
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
