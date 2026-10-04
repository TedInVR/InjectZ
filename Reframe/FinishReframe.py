#!/usr/bin/env python3
"""Validate Photos' edited exports and assemble stereo; no deletion or library changes."""
import argparse
import subprocess
import sys
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument('working_dir'); p.add_argument('source_photo')
p.add_argument('--format', choices=('Parallel','Crossview'), default='Parallel')
a = p.parse_args()
root = Path(a.working_dir).resolve()
def one_eye(name):
    folder = root/'Exports'/name
    images = [f for f in folder.iterdir() if f.is_file() and f.suffix.lower() in ('.jpg','.jpeg','.png','.tif','.tiff','.heic')]
    if len(images) != 1:
        raise RuntimeError(f'Expected one edited {name} export in {folder}, found {len(images)}. All files retained.')
    return images[0]
try:
    left, right = one_eye('LEFT'), one_eye('RIGHT')
    source = Path(a.source_photo).resolve()
    stem = source.stem + '_InjectZ_Reframe_' + a.format
    dest = source.with_name(stem+'.png')
    counter = 2
    while dest.exists():
        dest = source.with_name(f'{stem}_{counter}.png'); counter += 1
    assembler = Path(__file__).with_name('StereoAssembler.py')
    subprocess.run([sys.executable, str(assembler), str(left), str(right), '--format', a.format, '--output', str(dest)], check=True)
    if not dest.is_file() or dest.stat().st_size == 0: raise RuntimeError('Stereo output missing or empty.')
    print('SUCCESS:', dest)
    print('Original, Photos album and temporary files have NOT been deleted.')
except Exception as exc:
    sys.exit('STOPPED: '+str(exc))
