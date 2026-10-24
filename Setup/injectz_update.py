"""Inject Z source updater. Local build/sign first; code-only transactional install."""
import argparse,datetime,fcntl,hashlib,json,os,plistlib,re,shutil,stat,subprocess,sys,tempfile,time,urllib.request,zipfile
from pathlib import Path,PurePosixPath
REPO='TedInVR/InjectZ';ID='com.injectz.app.dev';LABEL=ID+'.automaticupdates'
HOSTS={'api.github.com','raw.githubusercontent.com','github.com','codeload.github.com'}

def version(value):
    if not isinstance(value,str) or not re.fullmatch(r'\d+\.\d+\.\d+',value):raise ValueError('Invalid update version.')
    return tuple(map(int,value.split('.')))

def safe_url(value):
    from urllib.parse import urlparse
    parsed=urlparse(value)
    if parsed.scheme!='https' or parsed.hostname not in HOSTS or parsed.username or parsed.password:raise ValueError('Unexpected update address.')
    return value

class Redirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,req,fp,code,msg,headers,newurl):return super().redirect_request(req,fp,code,msg,headers,safe_url(newurl))

def download(url,dest,limit=128*1024*1024):
    request=urllib.request.Request(safe_url(url),headers={'User-Agent':'InjectZ-Updater','Accept':'application/vnd.github+json'})
    with urllib.request.build_opener(Redirect()).open(request,timeout=30) as response,Path(dest).open('wb') as out:
        safe_url(response.geturl());count=0
        while True:
            block=response.read(1024*1024)
            if not block:break
            count+=len(block)
            if count>limit:raise ValueError('The update download is larger than expected.')
            out.write(block)

def remote_json(url):
    with tempfile.TemporaryDirectory() as td:
        dest=Path(td)/'data';download(url,dest,1024*1024);return json.loads(dest.read_text())

def installed_version(app):
    info=plistlib.loads((Path(app)/'Contents/Info.plist').read_bytes())
    if info.get('CFBundleIdentifier')!=ID:raise ValueError('The selected app is not Inject Z.')
    return info.get('CFBundleShortVersionString','0.0.0')

def enabled(root):
    try:return json.loads((Path(root)/'Updates/preferences.json').read_text()).get('automatic',True) is True
    except FileNotFoundError:return True
    except (OSError,ValueError):return False

def check(app):
    commit=remote_json(f'https://api.github.com/repos/{REPO}/commits/main')['sha']
    if not re.fullmatch('[0-9a-f]{40}',commit):raise ValueError('Invalid GitHub commit.')
    release=remote_json(f'https://raw.githubusercontent.com/{REPO}/{commit}/Setup/UpdateRelease.json')
    current=installed_version(app);latest=release['version'];version(latest)
    return dict(current=current,version=latest,sha=commit,available=version(latest)>version(current))

def allowed(name):
    path=PurePosixPath(name)
    if not name or '\\' in name or path.is_absolute() or '..' in path.parts or not path.parts:raise ValueError('Unsafe update filename.')
    if path.parts[0] not in {'App','SHARP','IW3','Reframe','SHARPDepthEditor','Assets','Setup'}:raise ValueError('Unexpected update folder.')
    if '__pycache__' in path.parts or path.suffix=='.pyc':raise ValueError('Python caches are not update payloads.')
    return path

def extract_verified(archive,repo):
    with zipfile.ZipFile(archive) as z:
        entries=z.infolist()
        if len(entries)>10000 or sum(x.file_size for x in entries)>400*1024*1024:raise ValueError('Oversized update archive.')
        roots=set();mapping={}
        for entry in entries:
            path=PurePosixPath(entry.filename)
            if path.is_absolute() or '..' in path.parts or '\\' in entry.filename or stat.S_ISLNK(entry.external_attr>>16):raise ValueError('Unsafe archive entry.')
            if not path.parts:continue
            roots.add(path.parts[0])
            if len(roots)>1:raise ValueError('Unexpected archive structure.')
            if len(path.parts)>1 and not entry.is_dir():
                name='/'.join(path.parts[1:])
                if name in mapping:raise ValueError('Duplicate archive entry.')
                mapping[name]=entry
        manifest=json.loads(z.read(mapping['Setup/UpdateManifest.json']))
        if not isinstance(manifest,dict) or not manifest.get('files'):raise ValueError('Missing update manifest.')
        for name,record in manifest['files'].items():
            allowed(name);data=z.read(mapping[name]);algorithm=record['algorithm'];expected=record['digest']
            if algorithm=='sha256':actual=hashlib.sha256(data).hexdigest()
            elif algorithm=='git-blob-sha1':actual=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
            else:raise ValueError('Unknown checksum algorithm.')
            if actual!=expected:raise ValueError('Update checksum failed: '+name)
            dest=repo/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        # Retain the exact manifest for a second validation before installation.
        (repo/'Setup/UpdateManifest.json').write_text(json.dumps(manifest))
        return manifest

def verify_repo(repo):
    manifest=json.loads((repo/'Setup/UpdateManifest.json').read_text())
    for name,record in manifest['files'].items():
        allowed(name);data=(repo/name).read_bytes()
        digest=hashlib.sha256(data).hexdigest() if record['algorithm']=='sha256' else hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
        if digest!=record['digest']:raise ValueError('Staged update changed: '+name)
    return manifest

def run(command,**kwargs):
    try:return subprocess.run(list(map(str,command)),check=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,**kwargs)
    except subprocess.CalledProcessError as error:
        raise RuntimeError(Path(str(command[0])).name+' failed: '+(error.stderr or b'').decode(errors='replace')[-8000:]) from error

def sign_like_existing(staged,existing,work):
    details=run(['/usr/bin/codesign','-dv','--verbose=4',existing]).stderr.decode(errors='replace')
    identity='-';options=[]
    if 'Signature=adhoc' not in details:
        prefix=work/'signer';run(['/usr/bin/codesign','-d','--extract-certificates',prefix,existing])
        certificate=Path(str(prefix)+'0')
        identity=hashlib.sha1(certificate.read_bytes()).hexdigest().upper()
        identities=run(['/usr/bin/security','find-identity','-v','-p','codesigning']).stdout.decode()
        if identity not in identities:raise RuntimeError('The existing signing certificate/private key is unavailable. The installed app has not been changed.')
        requirements=run(['/usr/bin/codesign','-d','-r-',existing]);text=(requirements.stdout+requirements.stderr).decode(errors='replace')
        match=re.search(r'(designated => .+)',text)
        if not match:raise RuntimeError('Could not preserve the installed signing requirement.')
        options+=['--requirements','='+match.group(1)]
    entitlements=run(['/usr/bin/codesign','-d','--entitlements',':-',existing]).stdout
    if b'<plist' in entitlements:
        start=entitlements.find(b'<?xml');start=start if start>=0 else entitlements.find(b'<plist')
        entitlements=entitlements[start:];plistlib.loads(entitlements)
        path=work/'entitlements.plist';path.write_bytes(entitlements);options+=['--entitlements',str(path)]
    if '(runtime)' in details:options+=['--options','runtime']
    run(['/usr/bin/codesign','--force','--sign',identity]+options+[str(staged)])
    run(['/usr/bin/codesign','--verify','--strict',staged])

def build(repo,app,job,release):
    staged=job/'InjectZ.app';shutil.copytree(app,staged,symlinks=True)
    # Keep the existing icon and unrecognized/custom resources. Refresh known assets.
    resources=staged/'Contents/Resources';resources.mkdir(parents=True,exist_ok=True)
    for name in ['InjectZHeader.png','InjectZ_User_Guide.html']:
        if (repo/'Assets'/name).exists():shutil.copy2(repo/'Assets'/name,resources/name)
    if (repo/'Assets/AudioAlerts').is_dir():shutil.copytree(repo/'Assets/AudioAlerts',resources/'AudioAlerts',dirs_exist_ok=True)
    info_path=staged/'Contents/Info.plist';info=plistlib.loads(info_path.read_bytes())
    if info.get('CFBundleIdentifier')!=ID or info.get('CFBundleExecutable')!='InjectZ':raise ValueError('Unexpected Inject Z bundle layout.')
    info['CFBundleShortVersionString']=release['version'];info['CFBundleVersion']=release['version'];info_path.write_bytes(plistlib.dumps(info))
    run(['/usr/bin/xcrun','swiftc','-O',repo/'App/InjectZ.swift','-o',staged/'Contents/MacOS/InjectZ','-framework','Cocoa','-framework','UniformTypeIdentifiers','-framework','ApplicationServices','-framework','WebKit','-framework','Quartz'])
    run(['/usr/bin/xcrun','swiftc','-O',repo/'Reframe/LibraryGuard.swift','-o',job/'LibraryGuard','-framework','Cocoa'])
    sign_like_existing(staged,app,job)

def prepare(root,app):
    release=check(app)
    if not release['available']:return release
    updates=root/'Updates';updates.mkdir(parents=True,exist_ok=True);job=Path(tempfile.mkdtemp(prefix='injectz-',dir=updates))
    try:
        archive=job/'source.zip';download(f"https://api.github.com/repos/{REPO}/zipball/{release['sha']}",archive)
        repo=job/'source';repo.mkdir();manifest=extract_verified(archive,repo)
        if manifest['version']!=release['version']:raise ValueError('The downloaded update version does not match.')
        build(repo,app,job,release);archive.unlink()
        record=dict(job=str(job),app=str(app),root=str(root),version=release['version'],sha=release['sha'])
        (job/'prepared.json').write_text(json.dumps(record));shutil.copy2(repo/'Setup/injectz_update.py',job/'apply.py')
        return dict(release,job=str(job))
    except BaseException:shutil.rmtree(job,ignore_errors=True);raise

def idle(root):
    # A closed GUI may still have an engine/editor subprocess finishing work.
    result=subprocess.run(['/usr/bin/pgrep','-x','InjectZ'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    if result.returncode==0:return False
    commands=run(['/bin/ps','-axo','command=']).stdout.decode(errors='replace')
    markers=[str(base/p) for base in {root,Path.home()/'InjectZ'} for p in ['injectz_engine.py','injectz_sharp_render.py','Development/SHARPDepthEditor/','Development/IW3/photo_iw3.py','Development/Reframe/']]
    return not any(marker in line for line in commands.splitlines() for marker in markers)

def payload_files(repo,root,job):
    files={repo/'App/InjectZ.swift':root/'InjectZ.swift',job/'LibraryGuard':root/'Development/Reframe/LibraryGuard',repo/'Setup/injectz_update.py':root/'Development/Updater/injectz_update.py'}
    for folder,target in [('SHARP',root),('Reframe',root/'Development/Reframe'),('SHARPDepthEditor',root/'Development/SHARPDepthEditor')]:
        for source in (repo/folder).iterdir():
            if source.is_file() and source.suffix in {'.py','.swift','.applescript','.json','.html','.js'}:files[source]=target/source.name
    for name,dest in [('photo_iw3.py',root/'Development/IW3/photo_iw3.py'),('create_layered_psd.py',root/'Development/create_layered_psd.py'),('IW3SettingHelp.json',root/'IW3SettingHelp.json')]:files[repo/'IW3'/name]=dest
    # IW3Settings.json is local/user configuration and is intentionally retained.
    return files

def copy_atomic(source,dest):
    dest.parent.mkdir(parents=True,exist_ok=True);temporary=dest.with_name(dest.name+'.updating');shutil.copy2(source,temporary);os.replace(temporary,dest)

def finish(job,root,app):
    job=job.resolve();root=root.resolve();app=app.resolve()
    if job.parent!=root/'Updates' or not job.name.startswith('injectz-'):raise ValueError('Unexpected update staging location.')
    record=json.loads((job/'prepared.json').read_text())
    if Path(record['app']).resolve()!=app or Path(record['root']).resolve()!=root:raise ValueError('Update destination changed.')
    repo=job/'source';manifest=verify_repo(repo)
    if version(record['version'])<=version(installed_version(app)):shutil.rmtree(job);return 'already current'
    if manifest['version']!=record['version']:raise ValueError('Prepared update version changed.')
    run(['/usr/bin/codesign','--verify','--strict',job/'InjectZ.app'])
    updates=root/'Updates';updates.mkdir(exist_ok=True)
    with (updates/'install.lock').open('a+b') as lock:
        try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:raise RuntimeError('Close Inject Z before installing. No installed files changed.')
        if not idle(root):raise RuntimeError('Inject Z or an engine/editor is still running. No installed files changed.')
        files=payload_files(repo,root,job)
        for dest in files.values():
            if not dest.resolve().is_relative_to(root):raise ValueError('A support-code path points outside Inject Z.')
            if any(parent.is_symlink() for parent in [dest]+list(dest.parents) if parent!=root and parent.is_relative_to(root)):raise ValueError('A support-code path is a symbolic link; no files were changed.')
        backup=root/'Backups'/('Before-'+record['version']+'-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'));backup.mkdir(parents=True)
        shutil.copytree(app,backup/'InjectZ.app',symlinks=True);existed={}
        for dest in files.values():
            existed[dest]=dest.exists()
            if dest.exists():copy_atomic(dest,backup/'files'/dest.relative_to(root))
        replacement=app.with_name(app.name+'.update-staging');old=app.with_name(app.name+'.previous-update')
        if replacement.exists() or old.exists():raise RuntimeError('An unfinished app replacement exists; see Updates/update.log before retrying.')
        shutil.copytree(job/'InjectZ.app',replacement,symlinks=True)
        try:
            for source,dest in files.items():copy_atomic(source,dest)
            os.rename(app,old);os.rename(replacement,app)
            run(['/usr/bin/codesign','--verify','--strict',app])
        except BaseException:
            if old.exists():
                if app.exists():shutil.rmtree(app)
                os.rename(old,app)
            if replacement.exists():shutil.rmtree(replacement)
            for dest,was in existed.items():
                if was:copy_atomic(backup/'files'/dest.relative_to(root),dest)
                elif dest.exists():dest.unlink()
            raise
        shutil.rmtree(old);os.utime(app,None)
    shutil.rmtree(job);return 'updated'

def register(root,app,automatic=None):
    updates=root/'Updates';updates.mkdir(parents=True,exist_ok=True)
    if automatic is not None:(updates/'preferences.json').write_text(json.dumps(dict(automatic=automatic)))
    agent=Path.home()/'Library/LaunchAgents'/(LABEL+'.plist');domain='gui/'+str(os.getuid())
    if not enabled(root):
        subprocess.run(['/bin/launchctl','bootout',domain+'/'+LABEL],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL);agent.unlink(missing_ok=True);return
    helper=root/'Development/Updater/injectz_update.py'
    data=plistlib.dumps(dict(Label=LABEL,ProgramArguments=[sys.executable,str(helper),'--root',str(root),'--app',str(app),'--automatic'],RunAtLoad=True,StartInterval=900,ProcessType='Background',StandardOutPath=str(updates/'automatic.log'),StandardErrorPath=str(updates/'automatic.log')))
    same=agent.exists() and agent.read_bytes()==data
    loaded=subprocess.run(['/bin/launchctl','print',domain+'/'+LABEL],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL).returncode==0
    if same and loaded:return
    if loaded:subprocess.run(['/bin/launchctl','bootout',domain+'/'+LABEL],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    agent.parent.mkdir(parents=True,exist_ok=True);temporary=agent.with_suffix('.tmp');temporary.write_bytes(data);os.replace(temporary,agent)
    run(['/bin/launchctl','bootstrap',domain,agent])

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--root',type=Path,default=Path.home()/'InjectZ');parser.add_argument('--app',type=Path);parser.add_argument('--check',action='store_true');parser.add_argument('--prepare',action='store_true');parser.add_argument('--finish',type=Path);parser.add_argument('--discard-job',type=Path);parser.add_argument('--wait-pid',type=int);parser.add_argument('--reopen',action='store_true');parser.add_argument('--register',action='store_true');parser.add_argument('--set-automatic',choices=['yes','no']);parser.add_argument('--automatic',action='store_true');args=parser.parse_args()
    root=args.root.resolve();app=(args.app or root/'InjectZ.app').resolve();job=None
    if sys.platform!='darwin':raise RuntimeError('Run the Inject Z updater on macOS.')
    try:
        if args.wait_pid:
            if args.wait_pid<=1:raise ValueError('Invalid app process.')
            deadline=time.monotonic()+120
            while time.monotonic()<deadline:
                try:os.kill(args.wait_pid,0)
                except ProcessLookupError:break
                time.sleep(.2)
            else:raise RuntimeError('Inject Z did not close. Nothing was installed.')
        if args.discard_job:
            discard=args.discard_job.resolve()
            if discard.parent!=root/'Updates' or not discard.name.startswith('injectz-'):raise ValueError('Unexpected discard folder.')
            shutil.rmtree(discard,ignore_errors=True);result=dict(status='discarded')
        elif args.register or args.set_automatic:
            register(root,app,None if not args.set_automatic else args.set_automatic=='yes');result=dict(automatic=enabled(root))
        elif args.finish:result=dict(status=finish(args.finish,root,app))
        elif args.automatic:
            if not enabled(root) or not idle(root):return
            result=prepare(root,app)
            if 'job' in result:
                job=Path(result['job'])
                if enabled(root) and idle(root):finish(job,root,app)
        elif args.prepare:result=prepare(root,app)
        else:result=check(app)
        print(json.dumps(result),flush=True)
        if args.reopen:subprocess.Popen(['/usr/bin/open','-n',str(app)])
    except Exception as error:
        (root/'Updates').mkdir(parents=True,exist_ok=True)
        with (root/'Updates/update.log').open('a') as log:log.write(datetime.datetime.now().isoformat()+' '+str(error)+'\n')
        print(json.dumps(dict(error=str(error)[:700])),flush=True)
        if args.reopen:
            try:
                if idle(root):subprocess.Popen(['/usr/bin/open','-n',str(app)])
            except Exception:pass
        return 1
    finally:
        if job and job.exists():shutil.rmtree(job,ignore_errors=True)
    return 0

if __name__=='__main__':sys.exit(main())
