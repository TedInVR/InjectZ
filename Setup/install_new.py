"""First-install preview. Existing installations are never overwritten."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import urllib.request

MODEL_URL = 'https://ml-site.cdn-apple.com/models/sharp/sharp_2572gikvuh.pt'
MODEL_SHA256 = '94211a75198c47f61fca7d739ba08a215418d8d398d48fddf023baccc24f073d'

def copy_sources(repo, root):
    for directory in ('App', 'SHARP', 'IW3', 'Reframe', 'Assets'):
        if not (repo / directory).is_dir():
            raise RuntimeError(f'Incomplete repository: missing {directory}')
    shutil.copy2(repo / 'App/InjectZ.swift', root / 'InjectZ.swift')
    for file in (repo / 'SHARP').glob('*.py'):
        shutil.copy2(file, root / file.name)
    reframe = root / 'Development/Reframe'
    reframe.mkdir(parents=True)
    for file in (repo / 'Reframe').iterdir():
        if file.is_file():
            shutil.copy2(file, reframe / file.name)
    iw3 = root / 'Development/IW3'
    iw3.mkdir()
    shutil.copy2(repo / 'IW3/photo_iw3.py', iw3 / 'photo_iw3.py')
    shutil.copy2(repo / 'IW3/create_layered_psd.py', root / 'Development/create_layered_psd.py')
    for name in ('IW3Settings.json', 'IW3SettingHelp.json'):
        shutil.copy2(repo / 'IW3' / name, root / name)

def download_verified(url, target, digest):
    partial = target.with_suffix(target.suffix + '.partial')
    check = hashlib.sha256()
    request = urllib.request.Request(url, headers={'User-Agent': 'InjectZ-Setup-Preview/0.1'})
    with urllib.request.urlopen(request, timeout=60) as response, partial.open('xb') as output:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            output.write(chunk)
            check.update(chunk)
    if check.hexdigest() != digest:
        raise RuntimeError('SHARP checkpoint checksum mismatch. Partial download retained; not installed.')
    partial.rename(target)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', required=True, type=Path)
    parser.add_argument('--iw3-python', required=True, type=Path)
    parser.add_argument('--sharp', choices=('yes', 'no'), required=True)
    args = parser.parse_args()
    root = Path.home() / 'InjectZ'
    if root.exists() or root.is_symlink():
        raise RuntimeError('Existing ~/InjectZ detected. Nothing changed.')
    if sys.platform != 'darwin' or platform.machine() != 'arm64':
        raise RuntimeError('Native Apple Silicon macOS execution is required.')
    if shutil.disk_usage(Path.home()).free < 15 * 1024**3:
        raise RuntimeError('At least 15 GB free is required to attempt setup; additional models may need more.')
    root.mkdir()  # Atomic refusal if another installation created it after checking.
    logpath = root / 'SETUP_LOG.txt'
    with logpath.open('x') as log:
        def run(command, cwd=None, capture=False):
            print('Running:', ' '.join(map(str, command)), flush=True)
            log.write('Running: ' + ' '.join(map(str, command)) + '\n')
            log.flush()
            process = subprocess.Popen(list(map(str, command)), cwd=cwd, env=dict(os.environ, HF_HUB_OFFLINE='0'), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            lines = []
            for line in process.stdout:
                print(line, end='', flush=True)
                log.write(line)
                log.flush()
                if capture:
                    lines.append(line)
            if process.wait() != 0:
                raise RuntimeError('A setup command failed; see ' + str(logpath))
            return ''.join(lines).strip()
        copy_sources(args.repo, root)
        sources = root / 'SetupSources'
        sources.mkdir()
        iw3root = root / 'Development/IW3'
        nunif = iw3root / 'nunif'
        run(['/usr/bin/git', 'clone', '--depth', '1', 'https://github.com/nagadomi/nunif.git', nunif])
        run([args.iw3_python, '-m', 'venv', iw3root / 'python'])
        iwpython = iw3root / 'python/bin/python'
        run([iwpython, '-m', 'pip', 'install', '--upgrade', 'pip'])
        run([iwpython, '-m', 'pip', 'install', 'torch', 'torchvision'])
        run([iwpython, '-m', 'pip', 'install', '-r', nunif / 'requirements.txt'], cwd=nunif)
        run([iwpython, '-m', 'pip', 'install', 'wxPython', 'Pillow', 'numpy', 'scipy'])
        run([iwpython, '-c', 'import torch,numpy,PIL,wx; assert torch.backends.mps.is_available(), "MPS is unavailable"'])
        run([iwpython, root / 'Development/IW3/photo_iw3.py', '--injectz-protect-window', '--help'], cwd=nunif)
        run([iwpython, args.repo / 'Setup/resolve_defaults.py', root / 'IW3Settings.json', root / 'IW3Settings.json'], cwd=nunif)
        provenance = {'nunif_commit': run(['/usr/bin/git', 'rev-parse', 'HEAD'], cwd=nunif, capture=True), 'status': 'Installed runtimes; model and real-photo tests pending', 'sharp': args.sharp}
        if args.sharp == 'yes':
            sharp = sources / 'ml-sharp'
            run(['/usr/bin/git', 'clone', '--depth', '1', 'https://github.com/apple-aiml-research/ml-sharp.git', sharp])
            runtime = root / 'Runtime/python'
            runtime.parent.mkdir()
            run([sys.executable, '-m', 'venv', runtime])
            python = runtime / 'bin/python3'
            run([python, '-m', 'pip', 'install', '--upgrade', 'pip'])
            run([python, '-m', 'pip', 'install', '-r', sharp / 'requirements.txt'], cwd=sharp)
            run([python, '-m', 'pip', 'install', 'metal-gauss==0.2.1', 'scipy'])
            run([python, '-c', 'import torch,inspect; from sharp.cli import main_cli; from metal_gauss.io import load_ply; from metal_gauss.metal_backend import render; from metal_gauss.render_path import frame_cloud,intrinsics,world_to_camera,render_frames,write_png; p=inspect.signature(render).parameters; assert "far" in p and "colors" in p; assert torch.backends.mps.is_available()'])
            modeldir = root / 'Models/SHARP'
            modeldir.mkdir(parents=True)
            print('Downloading the official SHARP checkpoint; checksum will be verified.', flush=True)
            download_verified(MODEL_URL, modeldir / 'sharp_2572gikvuh.pt', MODEL_SHA256)
            provenance['sharp_commit'] = run(['/usr/bin/git', 'rev-parse', 'HEAD'], cwd=sharp, capture=True)
        run(['/bin/bash', args.repo / 'Setup/BUILD_SOURCE.command'])
        candidates = sorted((args.repo / 'build').glob('InjectZ-*/InjectZ'), key=lambda x: x.stat().st_mtime)
        if not candidates:
            raise RuntimeError('Build staging folder was not produced.')
        built = candidates[-1]
        shutil.copytree(built / 'InjectZ.app', root / 'InjectZ.app')
        shutil.copy2(built / 'Development/Reframe/LibraryGuard', root / 'Development/Reframe/LibraryGuard')
        run(['/usr/bin/xattr', '-cr', root / 'InjectZ.app'])
        run(['/usr/bin/codesign', '--force', '--sign', '-', root / 'InjectZ.app'])
        run(['/usr/bin/codesign', '--verify', '--strict', root / 'InjectZ.app'])
        shutil.copy2(args.repo / 'Setup/DOWNLOAD_IW3_MODELS.command', root / 'DOWNLOAD_IW3_MODELS.command')
        (root / 'DOWNLOAD_IW3_MODELS.command').chmod(0o755)
        shutil.copy2(args.repo / 'Setup/MODEL_SETUP.txt', root / 'MODEL_SETUP.txt')
        (root / 'SetupProvenance.json').write_text(json.dumps(provenance, indent=2))
        print('New developer installation prepared. IW3 model downloads and real-photo tests remain.', flush=True)
        run(['/usr/bin/open', root])

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print('\nSETUP STOPPED:', error, file=sys.stderr)
        sys.exit(1)
