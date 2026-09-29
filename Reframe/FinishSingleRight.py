#!/usr/bin/env python3
"""One-eye Reframe assembly: source is untouched LEFT; edited export is RIGHT."""
import argparse, subprocess, sys, uuid, tempfile
from pathlib import Path
from PIL import Image, ImageOps
from WindowGuard import convergence_pixels
p=argparse.ArgumentParser()
p.add_argument('working_dir'); p.add_argument('source_photo')
p.add_argument('--formats',nargs='+',choices=['Parallel','Crossview','Anaglyph_FullColor','Anaglyph_HalfColor','Anaglyph_Dubois'],required=True)
p.add_argument('--pan',type=float,default=None)
p.add_argument('--allow-window-violations',action='store_true')
a=p.parse_args()
root=Path(a.working_dir).resolve(); source=Path(a.source_photo).resolve()
if not source.is_file(): sys.exit('Original source photograph missing; no assembly performed.')
folder=root/'Exports'/'RIGHT'
files=[f for f in folder.iterdir() if f.is_file() and f.suffix.lower() in ('.jpg','.jpeg','.png','.tif','.tiff','.heic')] if folder.is_dir() else []
if len(files)!=1: sys.exit(f'Expected exactly one edited RIGHT export, found {len(files)}. No files deleted.')
# Photos may export a reframed eye at a slightly different pixel size.
# Work at the smaller common canvas; never upscale either eye or change the original.
with tempfile.TemporaryDirectory(prefix='InjectZ-normalized-', dir=root) as scratch:
    with Image.open(source) as opened_left, Image.open(files[0]) as opened_right:
        left, right = ImageOps.exif_transpose(opened_left), ImageOps.exif_transpose(opened_right)
        original_size, edited_size = left.size, right.size
        left_path, right_path = source, files[0]
        if left.size != right.size:
            target = (min(left.width, right.width), min(left.height, right.height))
            aspect_difference = abs(left.width / left.height - right.width / right.height) / (left.width / left.height)
            if aspect_difference > .08:
                sys.exit(f'Photos export aspect ratio differs substantially: original {original_size}, edited {edited_size}. Working copies preserved.')
            left_path = Path(scratch) / 'LEFT.png'
            right_path = Path(scratch) / 'RIGHT.png'
            left = ImageOps.fit(left.convert('RGB'), target, method=Image.Resampling.LANCZOS)
            right = ImageOps.fit(right.convert('RGB'), target, method=Image.Resampling.LANCZOS)
            left.save(left_path)
            right.save(right_path)
            print(f'Normalized stereo eyes from {original_size} and {edited_size} to {target}.', flush=True)
        shift = 0 if a.allow_window_violations else convergence_pixels(left, right, a.pan or 0)
    dest=Path(scratch)/('Reframe_Parallel_'+uuid.uuid4().hex+'.png')
    assembler=Path(__file__).with_name('StereoAssembler.py')
    subprocess.run([sys.executable,str(assembler),str(left_path),str(right_path),'--format','Parallel',
                    '--convergence',str(shift),'--output',str(dest)],check=True)
    if not dest.is_file() or not dest.stat().st_size: sys.exit('Stereo output missing or empty.')
    formatter=Path(__file__).with_name('SharedStereoFormats.py')
    subprocess.run([sys.executable,str(formatter),str(dest),'--output-prefix',
                    str(source.with_name(source.stem+'_InjectZ_Reframe')),'--depth-token',
                    format(a.pan or 0, '.4f'),'--formats',*a.formats],check=True)
print('ASSEMBLY_COMPLETE Original and Photos working album preserved.')
