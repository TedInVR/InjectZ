"""Transactional code-only update; no model/environment/session paths are touched."""
from pathlib import Path
import datetime,shutil,subprocess,sys
repo,root,app=map(Path,sys.argv[1:])
files={repo/'App/InjectZ.swift':root/'InjectZ.swift'}
for folder,target in [('SHARP',root),('IW3',root),('Reframe',root/'Development/Reframe'),('SHARPDepthEditor',root/'Development/SHARPDepthEditor')]:
 for p in (repo/folder).iterdir():
  if p.is_file() and p.suffix in {'.py','.swift','.json','.html','.js','.applescript'}:
   dest=target/p.name
   if folder=='IW3' and p.name=='photo_iw3.py':dest=root/'Development/IW3/photo_iw3.py'
   if folder=='IW3' and p.name=='create_layered_psd.py':dest=root/'Development/create_layered_psd.py'
   files[p]=dest
backup=root/'Backups'/('Before-0.3.0-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'));backup.mkdir(parents=True)
shutil.copytree(root/'InjectZ.app',backup/'InjectZ.app')
existed={}
for dst in files.values():
 existed[dst]=dst.exists()
 if dst.exists():
  b=backup/'files'/dst.relative_to(root);b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dst,b)
try:
 for src,dst in files.items():
  dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
 shutil.rmtree(root/'InjectZ.app');shutil.copytree(app,root/'InjectZ.app')
 subprocess.run(['/usr/bin/codesign','--verify','--strict',str(root/'InjectZ.app')],check=True)
except Exception:
 if (root/'InjectZ.app').exists():shutil.rmtree(root/'InjectZ.app')
 shutil.copytree(backup/'InjectZ.app',root/'InjectZ.app')
 for dst,was in existed.items():
  if was:shutil.copy2(backup/'files'/dst.relative_to(root),dst)
  elif dst.exists():dst.unlink()
 raise
log=root/'Development/DEVELOPMENT_LOG.md';log.parent.mkdir(parents=True,exist_ok=True)
with log.open('a') as f:f.write('\n## Installed Inject Z 0.3.0\n- Source-based release update, editor/help included; manual GitHub Check for Updates added.\n- Models, runtimes and sessions preserved. Backup: '+str(backup)+'\n')
print('Backup:',backup)
