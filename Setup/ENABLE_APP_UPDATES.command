#!/bin/bash
# One-time activation for an existing installation. No models or runtimes replaced.
set -euo pipefail
root="$HOME/InjectZ"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
python=""
for candidate in "$root/Runtime/python/bin/python3" "$root/Development/IW3/python/bin/python" "$(command -v python3 || true)"; do
 if [[ -x "$candidate" ]] && "$candidate" -c 'import sys;assert sys.version_info>=(3,9)' >/dev/null 2>&1; then python="$candidate";break;fi
done
if [[ -z "$python" ]]; then echo 'No usable Python was found. The existing app was not changed.';read -r -p 'Press Return to close.';exit 1;fi
echo 'Quit Inject Z and close its depth editor/conversions before continuing.'
echo 'This builds the update locally and retains models, environments, settings and signing identity.'
if "$python" - "$root" <<'PY'
import hashlib,importlib.util,json,pathlib,subprocess,sys,tempfile,urllib.request
root=pathlib.Path(sys.argv[1]);app=root/'InjectZ.app'
def get(url):
 request=urllib.request.Request(url,headers={'User-Agent':'InjectZ-Update-Activation'})
 with urllib.request.urlopen(request,timeout=30) as response:return response.read()
sha=json.loads(get('https://api.github.com/repos/TedInVR/InjectZ/commits/main'))['sha']
if len(sha)!=40 or any(c not in '0123456789abcdef' for c in sha):raise RuntimeError('Invalid GitHub commit identifier.')
base='https://raw.githubusercontent.com/TedInVR/InjectZ/'+sha+'/'
manifest=json.loads(get(base+'Setup/UpdateManifest.json'))
data=get(base+'Setup/injectz_update.py');record=manifest['files']['Setup/injectz_update.py']
if record['algorithm']!='sha256' or hashlib.sha256(data).hexdigest()!=record['digest']:raise RuntimeError('Updater verification failed. Nothing was installed.')
with tempfile.TemporaryDirectory(prefix='InjectZ-activate-') as td:
 path=pathlib.Path(td)/'injectz_update.py';path.write_bytes(data)
 spec=importlib.util.spec_from_file_location('injectz_update',path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 if not module.idle(root):raise RuntimeError('Inject Z or its editor/engine is still running. Quit it and run this command again.')
 print('Downloading, verifying, compiling and signing the update. This can take several minutes.',flush=True)
 result=module.prepare(root,app)
 if 'job' in result:
  print(module.finish(pathlib.Path(result['job']),root,app),flush=True)
 module.register(root,app,True)
 subprocess.run(['/usr/bin/open',str(app)],check=True)
 print('Ready. Future updates can install automatically while Inject Z is closed.',flush=True)
PY
then echo 'Activation finished.';else echo 'Activation stopped. Your previous app is retained unless installation completed successfully. Copy the error above for help.';fi
read -r -p 'Press Return to close.'
