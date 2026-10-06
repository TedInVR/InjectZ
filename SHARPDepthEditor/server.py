import hashlib,json,os,secrets,subprocess,sys,threading,time,uuid,shutil
from pathlib import Path
from http.server import ThreadingHTTPServer,BaseHTTPRequestHandler
from urllib.parse import urlsplit,parse_qs
from PIL import Image,ImageOps
from manual_mask import apply_strokes,resize_selection
from region_state import normalize_regions,active_regions,repair_region
from shape_weights import validate_shape
ROOT=Path.home()/'InjectZ';HERE=Path(__file__).resolve().parent
TOKEN=secrets.token_urlsafe(24)
if os.environ.get('INJECTZ_EDITOR_EMBEDDED')=='1':
 import signal
 if os.getpgrp()!=os.getpid():os.setsid()
 def stop_editor(signum,frame):
  signal.signal(signal.SIGTERM,signal.SIG_IGN)
  os.killpg(os.getpgrp(),signal.SIGTERM)
  raise SystemExit(0)
 signal.signal(signal.SIGTERM,stop_editor)
photo=Path(sys.argv[1]) if len(sys.argv)>1 else Path(subprocess.check_output(['/usr/bin/osascript','-e','POSIX path of (choose file with prompt "Choose the photograph for SHARP Manual Depth Editor")'],text=True).strip())
work=ROOT/'Development'/'GuidedDepthSessions'/str(uuid.uuid4());work.mkdir(parents=True)
# Normalize orientation once; prediction and selection use this exact same image.
source=work/(photo.stem+'.png')
with Image.open(photo) as im:ImageOps.exif_transpose(im).convert('RGB').save(source)
with Image.open(source) as im:
 im.thumbnail((1100,1100));im.save(work/'selection.png')
regions=[];current=None;strokes=[];redo_strokes=[];editing_index=None;selection_offset=0;state={'busy':False,'message':'Draw a box around the object.','result':False}
lock=threading.Lock()
for old in sorted(work.parent.iterdir(),key=lambda p:p.stat().st_mtime,reverse=True):
 if old==work or not (old/'edits.json').exists():continue
 try: saved=json.loads((old/'edits.json').read_text())
 except (ValueError,OSError):continue
 if saved.get('original')!=str(photo):continue
 question='Resume the most recent guided selection for this photo? Your earlier session stays unchanged.'
 answer=subprocess.check_output(['/usr/bin/osascript','-e','button returned of (display dialog '+json.dumps(question)+' buttons {"Start Fresh", "Resume Selection"} default button "Resume Selection")'],text=True).strip()
 if answer=='Resume Selection':
  editing_index=saved.get('editing_index')
  for name in ['selection.json','mask.png','automatic-mask.png','manual-strokes.json','manual-redo.json','selection-size.json','shape-draft.json']:
   if (old/name).exists():shutil.copy2(old/name,work/name)
  if (work/'mask.png').exists():
   current=work/'mask.png'
   if not (work/'automatic-mask.png').exists():shutil.copy2(current,work/'automatic-mask.png')
  if (work/'manual-strokes.json').exists():strokes=json.loads((work/'manual-strokes.json').read_text())
  if (work/'manual-redo.json').exists():redo_strokes=json.loads((work/'manual-redo.json').read_text())
  if (work/'selection-size.json').exists():selection_offset=int(json.loads((work/'selection-size.json').read_text()))
  for region in saved.get('regions',[]):
   mask=work/('region-'+str(uuid.uuid4())+'.png')
   if Path(region['mask']).exists():
    shutil.copy2(region['mask'],mask);regions.append(dict(region,mask=str(mask)))
  state['message']='Earlier selection resumed. Inspect the green highlight before rendering.'
 break

normalize_regions(regions)
if editing_index is None and current is not None:
 matches=[i for i,r in enumerate(regions) if Path(r['mask']).read_bytes()==current.read_bytes()]
 if matches:editing_index=matches[-1]
 else:
  enabled=[i for i,r in enumerate(regions) if r.get('enabled',True)]
  if len(enabled)==1:editing_index=enabled[0]
  elif enabled and all(regions[i]['role']=='background' for i in enabled):editing_index=enabled[-1]
if editing_index is not None and not 0<=editing_index<len(regions):editing_index=None

def refresh_manual():
 base=work/'automatic-mask.png'
 if not base.exists():raise ValueError('Find Selection first, or resume an earlier selection.')
 with Image.open(base) as im:resize_selection(apply_strokes(im,strokes),selection_offset).save(work/'mask.png')
 (work/'manual-strokes.json').write_text(json.dumps(strokes))
 (work/'manual-redo.json').write_text(json.dumps(redo_strokes))
 (work/'selection-size.json').write_text(json.dumps(selection_offset))

def save_session():
 state['depth_stale']=True
 (work/'edits.json').write_text(json.dumps({'original':str(photo),'regions':regions,'editing_index':editing_index},indent=2))


def run(cmd,env=None):
 with open(work/'session.log','a') as log:
  p=subprocess.run(list(map(str,cmd)),env=env,stdout=log,stderr=subprocess.STDOUT)
 if p.returncode:raise RuntimeError('Operation failed. See '+str(work/'session.log'))

def render(baseline, repair=False, preview=False, depth=False):
 try:
  state['message']='Building a fresh SHARP reconstruction (first render only)…'
  model=work/'model';model.mkdir(exist_ok=True)
  ply=model/(source.stem+'.ply')
  env=os.environ.copy();env['TORCH_EXTENSIONS_DIR']=str(ROOT/'Runtime/torch_extensions')
  if not ply.exists():
   run([sys.executable,'-c','from sharp.cli import main_cli; main_cli()','--','predict','-i',source,'-o',model,'-c',ROOT/'Models/SHARP/sharp_2572gikvuh.pt','--device','mps','--no-render'],env)
  background=None
  if repair and not depth:
   from background_repair import build_background
   state['message']='Downloading/checking LaMa and reconstructing one shared background. Keep Terminal open; this may take several minutes…'
   background=work/'shared-background.png'
   sky=Path(repair_region(regions)['mask'])
   cache_key=hashlib.sha256(source.read_bytes()+sky.read_bytes()).hexdigest()
   cache=work/'background-cache.txt'
   if not background.exists() or not cache.exists() or cache.read_text()!=cache_key:
    build_background(source,sky,background,ROOT);cache.write_text(cache_key)
  renderer=(ROOT/'injectz_sharp_render.py').read_text()
  anchor='K = intrinsics(W, H, fov)'
  if renderer.count(anchor)!=1:raise RuntimeError('Installed renderer differs from expected version; original files unchanged.')
  renderer=renderer.replace(anchor,anchor+'\nexec(compile(Path('+repr(str(HERE/'edit_hook.py'))+').read_text(), "guided_depth_hook", "exec"))')
  (work/'renderer.py').write_text(renderer)
  env['PYTHONPATH']=str(HERE)+os.pathsep+str(ROOT)+os.pathsep+env.get('PYTHONPATH','')
  env['INJECTZ_GUIDED_SPEC']=json.dumps(active_regions(regions))
  if background:env['INJECTZ_REPAIR_BACKGROUND']=str(background)
  else:env.pop('INJECTZ_REPAIR_BACKGROUND',None)
  out=work/'temporary-render';shutil.rmtree(out,ignore_errors=True);out.mkdir()
  env.pop('INJECTZ_DEPTH_OUTPUT',None);env.pop('INJECTZ_DEPTH_REPAIR',None)
  if depth:
   env['INJECTZ_DEPTH_OUTPUT']=str(work)
   if repair:env['INJECTZ_DEPTH_REPAIR']='1'
  state['message']='Rendering edited stereo pair…'
  run([sys.executable,work/'renderer.py','--photo',source,'--ply',ply,'--baseline',f'{baseline:.3f}','--output-dir',out],env)
  if depth:
   state.update(message='Depth views ready. White = nearer; both use the original scale.',depth_revision=time.time(),depth_stale=False);return
  candidates=list(out.glob('*_Parallel_InjectZ_SHARP_Baseline*.png'))
  if len(candidates)!=1:raise RuntimeError('Could not identify rendered result.')
  if preview:
   shutil.copy2(candidates[0],work/'result.png');state.update(message='Stereo preview ready — no image saved beside the source.',result=True,result_revision=time.time());return
  label='GuidedRepair' if repair else 'Guided'
  name=f'{photo.stem}_InjectZ_SHARP_{label}_Parallel_Depth{baseline:.3f}'
  for i in range(10000):
   dest=photo.parent/(name+('' if i==0 else f'_{i}')+'.png')
   try:
    with dest.open('xb') as f, candidates[0].open('rb') as inp:shutil.copyfileobj(inp,f)
    break
   except FileExistsError:continue
  else:raise RuntimeError('Could not allocate output filename.')
  shutil.copy2(dest,work/'result.png')
  (work/'edits.json').write_text(json.dumps({'original':str(photo),'baseline':baseline,'regions':regions,'repair':repair,'result':str(dest),'editing_index':editing_index},indent=2))
  state.update(message='Saved beside original: '+dest.name,result=True,result_revision=time.time())
 except Exception as e:state['message']=str(e)
 finally:
  shutil.rmtree(work/'temporary-render',ignore_errors=True)
  state['busy']=False

class Handler(BaseHTTPRequestHandler):
 def log_message(self,*a):pass
 def send(self,data,kind='application/json',code=200):
  if isinstance(data,dict) and data.get('ok'):data=dict(data,can_undo=bool(strokes),can_redo=bool(redo_strokes),selection_offset=selection_offset)
  if not isinstance(data,bytes):data=json.dumps(data).encode()
  self.send_response(code);self.send_header('Content-Type',kind);self.send_header('Cache-Control','no-store');self.end_headers();self.wfile.write(data)
 def authorized(self):return parse_qs(urlsplit(self.path).query).get('token',[''])[0]==TOKEN or self.headers.get('X-Editor-Token')==TOKEN
 def do_GET(self):
  if not self.authorized():return self.send({'error':'Unauthorized'},code=403)
  path=urlsplit(self.path).path
  if path=='/':return self.send((HERE/'editor.html').read_bytes().replace(b'EDITOR_TOKEN',TOKEN.encode()),'text/html; charset=utf-8')
  if path=='/state':return self.send(dict(state,regions=len(regions),can_undo=bool(strokes),can_redo=bool(redo_strokes),edits=[dict(index=i,name=r['name'],amount=r['amount'],role=r['role'],enabled=r['enabled'],shape=r.get('shape',{})) for i,r in enumerate(regions)]))
  if path=='/selection':return self.send({'selection':json.loads((work/'selection.json').read_text()) if (work/'selection.json').exists() else None,'shape_draft':json.loads((work/'shape-draft.json').read_text()) if (work/'shape-draft.json').exists() else None,'mask':current is not None,'selection_offset':selection_offset,'manual_edits':len(strokes),'dirty':current is not None and (editing_index is None or current.read_bytes()!=Path(regions[editing_index]['mask']).read_bytes() or ((work/'shape-draft.json').exists() and validate_shape(json.loads((work/'shape-draft.json').read_text()))!=validate_shape(regions[editing_index].get('shape',{})))),'editing_index':editing_index,'editing_edit':regions[editing_index] if editing_index is not None else None})
  files={'/background':work/'shared-background.png','/photo':work/'selection.png','/mask':work/'mask.png','/result':work/'result.png','/depth-original':work/'depth-original.png','/depth-adjusted':work/'depth-adjusted.png'}
  if path in files and files[path].exists():return self.send(files[path].read_bytes(),'image/png')
  self.send({'error':'Not found'},code=404)
 def do_POST(self):
  global current,editing_index,selection_offset
  if not self.authorized():return self.send({'error':'Unauthorized'},code=403)
  try:
   with lock:
    if state['busy']:raise ValueError('Wait for the current operation to finish.')
    n=int(self.headers.get('Content-Length',0))
    if n>100000:raise ValueError('Request too large.')
    data=json.loads(self.rfile.read(n));path=urlsplit(self.path).path
    if path=='/shape-draft':
     shape=validate_shape(data);(work/'shape-draft.json').write_text(json.dumps(shape));save_session();self.send({'ok':True})
    elif path=='/select':
     spec=work/'selection.json';spec.write_text(json.dumps(data))
     # OpenCV is checked once at startup; segmentation runs in its available environment.
     run([SEG_PY,HERE/'segment.py',work/'selection.png',spec,work/'automatic-mask.png'])
     refresh_manual()
     current=work/'mask.png';save_session();self.send({'ok':True})
    elif path=='/samples':
     import math
     pts=data.get('points',[]);rect=data.get('rect')
     if not isinstance(pts,list) or len(pts)>5000:raise ValueError('Invalid sample list.')
     if rect is None:raise ValueError('No automatic selection box to save.')
     for point in pts:
      if len(point)!=3 or point[2] not in ('fg','bg') or not all(math.isfinite(float(v)) for v in point[:2]):raise ValueError('Invalid sample.')
     (work/'selection.json').write_text(json.dumps({'rect':rect,'points':pts}))
     save_session();state['message']='Sample deleted. Click Find Selection to recalculate; direct corrections stay fixed.';self.send({'ok':True})
    elif path=='/paint':
     if current is None:raise ValueError('Find Selection first.')
     candidate=list(strokes)+[data]
     with Image.open(work/'automatic-mask.png') as im:apply_strokes(im,candidate)
     strokes.append(data);redo_strokes.clear();refresh_manual();save_session();self.send({'ok':True})
    elif path=='/selection-size':
     if current is None:raise ValueError('Create or load a selection first.')
     value=float(data['pixels'])
     if not value.is_integer() or not -20<=value<=20:raise ValueError('Selection size must be a whole number from -20 to 20.')
     selection_offset=int(value);refresh_manual();save_session();self.send({'ok':True})
    elif path=='/undo-paint':
     if strokes:redo_strokes.append(strokes.pop())
     refresh_manual();save_session();self.send({'ok':True})
    elif path=='/redo-paint':
     if redo_strokes:strokes.append(redo_strokes.pop())
     refresh_manual();save_session();self.send({'ok':True})
    elif path=='/clear-paint':
     strokes.clear();redo_strokes.clear();refresh_manual();save_session();self.send({'ok':True})
    elif path=='/add':
     amount=float(data['amount'])
     if current is None or not -0.9<=amount<=2:raise ValueError('Select a region first; adjustment must be -0.9 to 2.')
     mask=work/('region-'+str(uuid.uuid4())+'.png');shutil.copy2(current,mask)
     name=str(data.get('name','')).strip()[:80] or 'Change '+str(len(regions)+1)
     role=data.get('role','depth')
     if role not in ('background','depth'):raise ValueError('Unknown edit type.')
     shape=validate_shape(data.get('shape',{}))
     if role=='background' and shape['mode']!='uniform':raise ValueError('Sky repair uses a uniform plane. Use Object depth adjustment for shaped changes.')
     region={'mask':str(mask),'amount':amount,'name':name,'role':role,'enabled':True,'shape':shape}
     index=data.get('replace',editing_index)
     if index is None:
      regions.append(region);editing_index=len(regions)-1
     else:
      index=int(index)
      if not 0<=index<len(regions):raise ValueError('Saved edit no longer exists.')
      regions[index]=region;editing_index=index
     save_session();self.send({'ok':True,'index':editing_index})
    elif path=='/region-update':
     index=int(data['index']);region=regions[index]
     if 'amount' in data:
      amount=float(data['amount'])
      if not -.9<=amount<=2:raise ValueError('Adjustment must be -0.9 to 2.')
      region['amount']=amount
     if 'name' in data:region['name']=str(data['name']).strip()[:80] or 'Change '+str(index+1)
     if 'enabled' in data:region['enabled']=bool(data['enabled'])
     if 'role' in data:
      if data['role'] not in ('background','depth'):raise ValueError('Unknown edit type.')
      region['role']=data['role']
     save_session();self.send({'ok':True})
    elif path=='/region-delete':
     index=int(data['index']);regions.pop(index)
     if editing_index==index:editing_index=None
     elif editing_index is not None and editing_index>index:editing_index-=1
     save_session();self.send({'ok':True})
    elif path=='/bind-edit':
     index=int(data['index'])
     if not 0<=index<len(regions):raise ValueError('Saved edit no longer exists.')
     editing_index=index;save_session();self.send({'ok':True})
    elif path=='/region-merge':
     from region_state import merge_masks
     indices=sorted(set(int(i) for i in data['indices']))
     if len(indices)<2 or any(i<0 or i>=len(regions) for i in indices):raise ValueError('Choose at least two saved edits.')
     selected_regions=[regions[i] for i in indices]
     if len(set(r['role'] for r in selected_regions))!=1:raise ValueError('Merge sky edits together or object edits together; do not mix these types.')
     mask=work/('region-'+str(uuid.uuid4())+'.png')
     merge_masks([r['mask'] for r in selected_regions],data.get('mode','latest'),mask)
     merged=dict(selected_regions[-1],mask=str(mask),enabled=True)
     first=indices[0];regions[:]=[r for i,r in enumerate(regions) if i not in indices];regions.insert(first,merged);editing_index=None
     save_session();self.send({'ok':True,'index':first})
    elif path=='/region-load':
     editing_index=int(data['index']);region=regions[editing_index]
     (work/'shape-draft.json').write_text(json.dumps(region.get('shape',{})))
     shutil.copy2(region['mask'],work/'automatic-mask.png');selection_offset=0;strokes.clear();redo_strokes.clear();refresh_manual();current=work/'mask.png'
     with Image.open(current) as im:w,h=im.size
     (work/'selection.json').write_text(json.dumps({'rect':[0,0,w-1,h-1],'points':[]}))
     save_session();self.send({'ok':True})
    elif path=='/new-selection':
     strokes.clear();redo_strokes.clear();current=None;editing_index=None;selection_offset=0
     for name in ['mask.png','automatic-mask.png','manual-strokes.json','selection.json','shape-draft.json']:(work/name).unlink(missing_ok=True)
     save_session();self.send({'ok':True})
    elif path=='/undo':
     if regions:regions.pop()
     if editing_index is not None and editing_index>=len(regions):editing_index=None
     save_session()
     self.send({'ok':True})
    elif path=='/reset':regions.clear();editing_index=None;save_session();self.send({'ok':True})
    elif path in ('/render','/preview','/depth'):
     baseline=round(float(data['baseline']),3)
     if not .001<=baseline<=10:raise ValueError('Baseline must be 0.001 to 10.000.')
     repair=bool(data.get('repair',False))
     if path=='/depth' and not any(r.get('role')=='background' for r in active_regions(regions)):repair=False
     if repair:repair_region(regions)
     state.update(busy=True,result=False,message='Starting…')
     threading.Thread(target=render,args=(baseline,repair,path=='/preview',path=='/depth'),daemon=True).start();self.send({'ok':True})
    else:raise ValueError('Unknown action.')
  except Exception as e:self.send({'error':str(e)},code=400)

SEG_PY=None
for py in [Path(sys.executable),ROOT/'Development/IW3/python/bin/python']:
 if py.exists() and subprocess.run([str(py),'-c','import cv2,numpy; from PIL import Image'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0:SEG_PY=str(py);break
if not SEG_PY:raise SystemExit('OpenCV segmentation dependency not found in existing Inject Z environments. No app files changed.')
http=ThreadingHTTPServer(('127.0.0.1',0),Handler)
url=f'http://127.0.0.1:{http.server_port}/?token={TOKEN}'
if os.environ.get('INJECTZ_EDITOR_EMBEDDED')=='1':
 Path(os.environ['INJECTZ_EDITOR_URL_FILE']).write_text(url)
else:subprocess.run(['/usr/bin/open',url])
print('SHARP Manual Depth Editor ready. Session:',work,flush=True)
try:http.serve_forever()
except KeyboardInterrupt:http.server_close()
