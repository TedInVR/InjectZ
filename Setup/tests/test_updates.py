import hashlib,importlib.util,json,plistlib,shutil,sys,tempfile,zipfile,types
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('injectz_update',Path(__file__).resolve().parents[1]/'injectz_update.py');u=importlib.util.module_from_spec(spec);spec.loader.exec_module(u)
def app(root,version):
 p=root/'Contents/Info.plist';p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(plistlib.dumps(dict(CFBundleIdentifier=u.ID,CFBundleExecutable='InjectZ',CFBundleShortVersionString=version)))
 (root/'Contents/Resources').mkdir(exist_ok=True);(root/'Contents/Resources/icon.icns').write_bytes(b'original icon')
def candidate(root):
 job=root/'Updates/injectz-test';repo=job/'source';repo.mkdir(parents=True)
 names={'App/InjectZ.swift':'new GUI','Setup/injectz_update.py':'new updater','SHARP/injectz_engine.py':'new engine','Reframe/LibraryGuard.swift':'guard','SHARPDepthEditor/server.py':'editor','IW3/photo_iw3.py':'iw3','IW3/create_layered_psd.py':'psd','IW3/IW3SettingHelp.json':'{}','IW3/IW3Settings.json':'{"overwrite":"no"}'}
 for name,text in names.items():p=repo/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
 manifest=dict(version='0.3.1',files={name:dict(algorithm='sha256',digest=hashlib.sha256(text.encode()).hexdigest()) for name,text in names.items()})
 (repo/'Setup/UpdateManifest.json').write_text(json.dumps(manifest));app(job/'InjectZ.app','0.3.1');(job/'LibraryGuard').write_text('compiled guard')
 (job/'prepared.json').write_text(json.dumps(dict(root=str(root),app=str(root/'InjectZ.app'),version='0.3.1')))
 return job,repo,manifest
with tempfile.TemporaryDirectory() as td:
 root=Path(td)/'InjectZ';root.mkdir();app(root/'InjectZ.app','0.3.0');(root/'InjectZ.swift').write_text('old GUI')
 for name,data in [('Models/model.pt',b'large model'),('Runtime/python/marker',b'runtime'),('IW3Settings.json',b'{"user":"keep"}'),('Development/SHARPDepthEditor/sessions/saved.json',b'saved session')]:
  p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 before={p:p.read_bytes() for p in root.rglob('*') if p.is_file() and p.name!='Info.plist'}
 job,repo,manifest=candidate(root)
 archive=Path(td)/'repo.zip'
 with zipfile.ZipFile(archive,'w') as z:
  for p in repo.rglob('*'):
   if p.is_file():z.write(p,'repo/'+str(p.relative_to(repo)))
 extracted=Path(td)/'extracted';extracted.mkdir();assert u.extract_verified(archive,extracted)['version']=='0.3.1';u.verify_repo(extracted)
 with patch.object(u,'run',return_value=types.SimpleNamespace(stdout=b'',stderr=b'')),patch.object(u,'idle',return_value=True):assert u.finish(job,root,root/'InjectZ.app')=='updated'
 assert u.installed_version(root/'InjectZ.app')=='0.3.1' and (root/'InjectZ.swift').read_text()=='new GUI' and not job.exists()
 for p,data in before.items():
  if p.name!='InjectZ.swift':assert p.read_bytes()==data,str(p)
 assert (root/'Development/Updater/injectz_update.py').read_text()=='new updater'
 assert any((root/'Backups').iterdir())
 # An interrupted code copy restores the GUI/support files and preserves all data.
 app(root/'InjectZ.app','0.3.0');(root/'InjectZ.swift').write_text('old GUI');job,repo,manifest=candidate(root)
 original=u.copy_atomic;count=[0]
 def fail_once(src,dest):
  count[0]+=1
  if count[0]==2:raise OSError('simulated interrupted copy')
  return original(src,dest)
 with patch.object(u,'run',return_value=types.SimpleNamespace(stdout=b'',stderr=b'')),patch.object(u,'idle',return_value=True),patch.object(u,'copy_atomic',fail_once):
  try:u.finish(job,root,root/'InjectZ.app')
  except OSError:pass
  else:raise AssertionError('Copy failure ignored')
 assert (root/'InjectZ.swift').read_text()=='old GUI' and u.installed_version(root/'InjectZ.app')=='0.3.0'
 assert (root/'IW3Settings.json').read_bytes()==before[root/'IW3Settings.json']
 # An active app/editor blocks every write.
 with patch.object(u,'run',return_value=types.SimpleNamespace(stdout=b'',stderr=b'')),patch.object(u,'idle',return_value=False):
  try:u.finish(job,root,root/'InjectZ.app')
  except RuntimeError:pass
  else:raise AssertionError('Running work not protected')
 assert (root/'InjectZ.swift').read_text()=='old GUI'
 # Bad paths and corrupted data cannot pass verification.
 for name in ['../escape','/absolute','Models/weights.pt','SHARP/../../escape']:
  try:u.allowed(name)
  except ValueError:pass
  else:raise AssertionError('Unsafe path accepted')
 (repo/'App/InjectZ.swift').write_text('corrupt')
 try:u.verify_repo(repo)
 except ValueError:pass
 else:raise AssertionError('Corrupt source accepted')
 for name in ['../escape','repo/../../escape']:
  with zipfile.ZipFile(archive,'w') as z:z.writestr(name,'bad')
  try:u.extract_verified(archive,extracted)
  except ValueError:pass
  else:raise AssertionError('Traversal archive accepted')
 # Ad-hoc signing stays ad hoc; no personal signing key is embedded in sources.
 commands=[]
 def sign(command,**kwargs):
  commands.append(list(map(str,command)));return types.SimpleNamespace(stdout=b'',stderr=b'Signature=adhoc\n' if '-dv' in command else b'')
 with patch.object(u,'run',sign):u.sign_like_existing(root/'InjectZ.app',root/'InjectZ.app',Path(td))
 assert any('--sign' in c and '-' in c for c in commands)
 # A certificate-signed installation selects the same certificate fingerprint.
 commands=[];certificate=b'public certificate bytes';fingerprint=hashlib.sha1(certificate).hexdigest().upper()
 def certified(command,**kwargs):
  commands.append(list(map(str,command)))
  if '-dv' in command:return types.SimpleNamespace(stdout=b'',stderr=b'Authority=Local Inject Z Certificate\nflags=0x10000(runtime)')
  if '--extract-certificates' in command:
   Path(str(command[command.index('--extract-certificates')+1])+'0').write_bytes(certificate)
  if 'find-identity' in command:return types.SimpleNamespace(stdout=fingerprint.encode(),stderr=b'')
  if '-r-' in command:return types.SimpleNamespace(stdout=b'designated => identifier "com.injectz.app.dev"',stderr=b'')
  return types.SimpleNamespace(stdout=b'',stderr=b'')
 with patch.object(u,'run',certified):u.sign_like_existing(root/'InjectZ.app',root/'InjectZ.app',Path(td))
 assert any('--sign' in c and fingerprint in c and '--requirements' in c and '--options' in c for c in commands)
print('Inject Z updater: archive/checksum validation, code-only installation, icon/model/runtime/session/settings preservation, rollback, active-work protection and ad-hoc signing command selection passed. Native macOS build/signing is not verified here.')
