"""Exercise the production wiggle export block with synthetic camera renders."""
import ast
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from PIL import Image
import numpy as np

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'Reframe'))
sys.path.insert(0, str(root / 'SHARP'))
import SharedStereoFormats  # noqa: F401

module = ast.parse((root / 'SHARP/injectz_sharp_render.py').read_text())
block = next(n for n in module.body if isinstance(n, ast.If)
             and isinstance(n.test, ast.Attribute) and n.test.attr == 'wiggle_frames')
compiled = compile(ast.Module(body=[block], type_ignores=[]), 'wiggle-test', 'exec')

class Torch:
    float32 = 'float32'
    @staticmethod
    def tensor(value, dtype=None): return value

class Arguments:
    wiggle_pivot_request = None
    wiggle_frames = 60
    wiggle_fps = 24
    wiggle_border = 0
    wiggle_corners = 0
    wiggle_card_color = None
    wiggle_card_title = ''
    soften_depth_edges = False
    edge_soften_strength = 0
    export_wiggle_views = True
    no_wiggle_video = True

with tempfile.TemporaryDirectory() as tmp:
    folder = Path(tmp)
    env = dict(a=Arguments(), sys=sys, Path=Path, shutil=shutil, tempfile=tempfile, os=os,
               subprocess=subprocess, Image=Image, OUTDIR=folder, PHOTO=Path('test.jpg'),
               BASELINE=.06, left_img=Image.new('RGB', (40, 30), 'red'),
               right_img=Image.new('RGB', (40, 30), 'blue'), torch=Torch, R=None,
               world_to_camera=lambda rotation, center: center,
               render_frames_with_scene_distance=lambda *args, **kwargs: iter([0]),
               sp=None, K=None, original_w=40, W=40, H=30, injectz_far_clip=100,
               crop_shift=0, write_png=lambda rgb, path, w, h: Image.new('RGB', (w, h), 'green').save(path))
    exec(compiled, env)
    views = folder/'test_InjectZ_SHARP_Views_Baseline0.060'
    files = sorted(views.glob('*.png'))
    assert len(files) == 62
    assert files[0].name == 'view_0001.png' and files[-1].name == 'view_0062.png'
    with Image.open(files[0]) as first, Image.open(files[-1]) as last:
        assert first.size == last.size == (40, 30)
        assert first.getpixel((20, 15)) == (255, 0, 0)
        assert last.getpixel((20, 15)) == (0, 0, 255)
    # A chosen pivot uses a separately rendered common-overlap sequence,
    # leaving the ordinary still-eye images untouched.
    class Tensor:
        def __init__(self, value): self.value = np.asarray(value)
        def detach(self): return self
        def cpu(self): return self
        def numpy(self): return self.value
        def __getitem__(self, index): return self.value[index]
    class Splats:
        means = Tensor([[0, 0, 2]])
        opacities = Tensor([1])
    args = Arguments(); args.wiggle_frames = 4
    args.wiggle_pivot_request = folder/'pivot.request'
    args.wiggle_pivot_request.with_suffix('.response').write_text(json.dumps({'mode':'point','x':.5,'y':.5}))
    env.update(a=args, sp=Splats(), K=Tensor([[100,0,20],[0,100,15],[0,0,1]]),
               PHOTO=Path('pivot.jpg'), json=json, time=time)
    exec(compiled, env)
    pivot_views = sorted((folder/'pivot_InjectZ_SHARP_Views_Baseline0.060').glob('*.png'))
    assert len(pivot_views) == 6
    with Image.open(pivot_views[0]) as first, Image.open(pivot_views[-1]) as last:
        assert first.size == last.size == (37, 30)
    assert env['left_img'].size == env['right_img'].size == (40, 30)
    assert not list(folder.glob('*.mp4'))
    if shutil.which('ffmpeg'):
        args = Arguments(); args.wiggle_frames = 4; args.no_wiggle_video = False
        args.export_wiggle_views = False; env['a'] = args; env['PHOTO'] = Path('test.jpg')
        exec(compiled, env)
        assert (folder/'test_InjectZ_SHARP_Wiggle_Baseline0.060.mp4').stat().st_size > 0
        args.export_wiggle_views = True
        args.wiggle_card_color = '#c68833'; args.wiggle_card_title = ''
        env['PHOTO'] = Path('combined.jpg')
        exec(compiled, env)
        combined = folder/'combined_InjectZ_SHARP_Views_Baseline0.060'
        assert len(list(combined.glob('view_*.png'))) == 6
        assert (folder/'combined_InjectZ_SHARP_Wiggle_Baseline0.060.mp4').stat().st_size > 0
        with Image.open(combined/'view_0001.png') as first:
            assert first.getpixel((0, 0)) == (198, 136, 51)
print('Views-only and video-only wiggle export paths passed.')
