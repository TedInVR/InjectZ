import ast,io,json,threading,tempfile
from shape_weights import validate_shape
from pathlib import Path
from http.server import BaseHTTPRequestHandler
from PIL import Image
from manual_mask import apply_strokes,resize_selection
from region_state import normalize_regions,active_regions,repair_region
source=ast.parse(Path(__file__).with_name('server.py').read_text())
subset=ast.Module(body=[n for n in source.body if isinstance(n,(ast.FunctionDef,ast.ClassDef)) and n.name in ('refresh_manual','save_session','Handler')],type_ignores=[])
with tempfile.TemporaryDirectory() as tmp:
 work=Path(tmp);photo=work/'original.png';Image.new('L',(30,20),255).save(work/'automatic-mask.png');Image.new('L',(30,20),255).save(work/'mask.png')
 ns=dict(BaseHTTPRequestHandler=BaseHTTPRequestHandler,Path=Path,Image=Image,apply_strokes=apply_strokes,resize_selection=resize_selection,selection_offset=0,work=work,photo=photo,editing_index=None,current=work/'mask.png',regions=[],strokes=[],redo_strokes=[],state={'busy':False},lock=threading.Lock(),json=json)
 import shutil,uuid
 from urllib.parse import urlsplit
 ns.update(validate_shape=validate_shape,shutil=shutil,uuid=uuid,urlsplit=urlsplit)
 exec(compile(subset,'editor_server_subset','exec'),ns)
 Handler=ns['Handler']
 def post(path,data):
  h=Handler.__new__(Handler);h.path=path;h.authorized=lambda:True;payload=json.dumps(data).encode();h.headers={'Content-Length':str(len(payload))};h.rfile=io.BytesIO(payload);response=[];h.send=lambda obj,**kw:response.append(obj);h.do_POST();assert response and not response[0].get('error'),response
 post('/paint',{'kind':'exclude','shape':'rectangle','points':[[5,5],[10,10]]})
 painted=(work/'mask.png').read_bytes()
 post('/undo-paint',{});assert len(ns['strokes'])==0 and len(ns['redo_strokes'])==1
 post('/redo-paint',{});assert (work/'mask.png').read_bytes()==painted
 post('/undo-paint',{});post('/paint',{'kind':'exclude','shape':'brush','radius':2,'points':[[15,15]]})
 assert not ns['redo_strokes']
 post('/add',{'amount':-.15,'name':'Sky','role':'background'})
 sky=ns['regions'][0]['mask'];original=Path(sky).read_bytes()
 post('/new-selection',{})
 assert len(ns['regions'])==1 and Path(sky).read_bytes()==original and ns['current'] is None
 post('/region-load',{'index':0});assert ns['current'].exists()
 post('/add',{'amount':.2,'name':'Foreground','role':'depth','replace':None})
 assert len(ns['regions'])==2 and repair_region(ns['regions'])['name']=='Sky'
 post('/region-update',{'index':1,'amount':.3,'name':'Body','enabled':False})
 assert len(active_regions(ns['regions']))==1
 saved=json.loads((work/'edits.json').read_text());assert saved['regions'][1]['name']=='Body'
 post('/region-load',{'index':0})
 post('/add',{'amount':-.2,'name':'Distant sky','role':'background','replace':0})
 assert len(ns['regions'])==2 and ns['regions'][0]['name']=='Distant sky'
 post('/region-delete',{'index':1});assert len(ns['regions'])==1
 post('/add',{'amount':-.25,'name':'Current sky','role':'background'});assert len(ns['regions'])==1 and ns['editing_index']==0
 post('/add',{'amount':-.3,'name':'Sky revision','role':'background','replace':None})
 post('/add',{'amount':-.4,'name':'Sky newest','role':'background','replace':None})
 post('/region-merge',{'indices':[0,1,2],'mode':'latest'})
 assert len(ns['regions'])==1 and ns['regions'][0]['amount']==-.4
 post('/region-load',{'index':0});assert ns['editing_index']==0
print('PASS: named edit save/load/update/toggle/delete, independent masks, start-new preserves saved edits.')
# Tests above cover endpoint setup; merger semantics are checked independently.
from region_state import merge_masks
import numpy as np
with tempfile.TemporaryDirectory() as tmp:
 folder=Path(tmp);a=np.zeros((8,8),np.uint8);a[1:5,1:5]=255;b=a.copy();b[2:4,2:4]=0
 Image.fromarray(a).save(folder/'old.png');Image.fromarray(b).save(folder/'new.png')
 merge_masks([folder/'old.png',folder/'new.png'],'latest',folder/'latest.png')
 assert np.array_equal(np.array(Image.open(folder/'latest.png')),b)
 merge_masks([folder/'old.png',folder/'new.png'],'union',folder/'union.png')
 assert np.array_equal(np.array(Image.open(folder/'union.png')),a)
print('PASS: revision merge keeps newest exclusions; union merge combines masks explicitly.')
