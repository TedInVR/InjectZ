import ast,tempfile,os,json,shutil,sys,time
from pathlib import Path
from PIL import Image
from region_state import active_regions,repair_region
src=Path(__file__).with_name('server.py').read_text();tree=ast.parse(src)
node=next(n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name=='render')
with tempfile.TemporaryDirectory() as tmp:
 root=Path(tmp);work=root/'session';work.mkdir();photo=root/'source.png';Image.new('RGB',(10,10)).save(photo);source=work/'source.png';shutil.copy2(photo,source)
 (work/'model').mkdir();(work/'model/source.ply').write_text('mock')
 (root/'injectz_sharp_render.py').write_text('K = intrinsics(W, H, fov)')
 state={};regions=[]
 def run(cmd,env):
  if env.get('INJECTZ_DEPTH_OUTPUT'):
   for name in ('depth-original','depth-adjusted'):Image.new('L',(10,10)).save(work/(name+'.png'))
  else:Image.new('RGB',(10,10)).save(Path(cmd[-1])/'source_Parallel_InjectZ_SHARP_Baseline0.060.png')
 ns=dict(state=state,work=work,ROOT=root,HERE=Path(__file__).parent,source=source,photo=photo,os=os,sys=sys,json=json,shutil=shutil,run=run,active_regions=active_regions,repair_region=repair_region,regions=regions,editing_index=None,time=time)
 exec(compile(ast.Module(body=[node],type_ignores=[]),'render_test','exec'),ns)
 ns['render'](.06,preview=True);assert state['result'] and (work/'result.png').exists();assert len(list(root.glob('*Depth*.png')))==0 and not (work/'temporary-render').exists()
 ns['render'](.06);assert len(list(root.glob('*Depth*.png')))==1
 ns['render'](.06);assert len(list(root.glob('*Depth*.png')))==2
 ns['render'](.06,depth=True);assert (work/'depth-original.png').exists() and state['depth_revision'] and not (work/'temporary-render').exists()
 print('PASS: mocked renderer orchestration: preview saves no source-side image, final saves avoid overwrites, depth-only works, temporary outputs cleaned.')
