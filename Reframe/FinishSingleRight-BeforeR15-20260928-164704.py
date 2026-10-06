#!/usr/bin/env python3
"""One-eye Reframe assembly: source is untouched LEFT; edited export is RIGHT."""
import argparse, subprocess, sys, uuid
from pathlib import Path
from PIL import Image
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
with Image.open(source) as li, Image.open(files[0]) as ri:
    shift = 0 if a.allow_window_violations else convergence_pixels(li, ri, a.pan or 0)
dest=root/('Reframe_Parallel_'+uuid.uuid4().hex+'.png')
assembler=Path(__file__).with_name('StereoAssembler.py')
subprocess.run([sys.executable,str(assembler),str(source),str(files[0]),'--format','Parallel','--convergence',str(shift),'--output',str(dest)],check=True)
if not dest.is_file() or not dest.stat().st_size: sys.exit('Stereo output missing or empty.')
formatter=Path(__file__).with_name('SharedStereoFormats.py')
subprocess.run([sys.executable,str(formatter),str(dest),'--output-prefix',
                str(source.with_name(source.stem+'_InjectZ_Reframe')),'--depth-token',
                format(a.pan or 0, '.4f'),'--formats',*a.formats],check=True)
dest.unlink()
print('ASSEMBLY_COMPLETE Original and Photos working album preserved.')
