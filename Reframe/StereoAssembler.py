#!/usr/bin/env python3
"""Assemble two exported Reframe views, without upscaling or black matte."""
import argparse
from pathlib import Path
from PIL import Image
p = argparse.ArgumentParser()
p.add_argument('left'); p.add_argument('right'); p.add_argument('--format', choices=['Parallel','Crossview'],default='Parallel')
p.add_argument('--convergence',type=int,default=0,help='Relative horizontal pixel shift; crops both images to common valid area')
p.add_argument('--output')
a=p.parse_args()
with Image.open(a.left) as li, Image.open(a.right) as ri:
    l=li.convert('RGB'); r=ri.convert('RGB')
if l.size != r.size: p.error('Both exports must have identical pixel dimensions.')
w,h=l.size; s=a.convergence
if abs(s)>=w//4: p.error('Convergence is too large for the image width.')
# Opposing shifts with symmetric valid-area cropping: no generated black edges.
if s>0:
    l=l.crop((s,0,w,h)); r=r.crop((0,0,w-s,h))
elif s<0:
    s=-s; l=l.crop((0,0,w-s,h)); r=r.crop((s,0,w,h))
out=Image.new('RGB',(l.width*2,h))
first,second=(l,r) if a.format=='Parallel' else (r,l)
out.paste(first,(0,0)); out.paste(second,(l.width,0))
path=Path(a.output) if a.output else Path(a.left).with_name(Path(a.left).stem+'_InjectZ_Reframe_'+a.format+'.png')
if path.exists(): p.error('Output already exists; provide a different --output path.')
out.save(path)
print(path)
