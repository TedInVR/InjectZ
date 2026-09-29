#!/usr/bin/env python3
import argparse, os, shutil, subprocess
from pathlib import Path

HOME=Path.home()
INJECTZ_DIR=HOME/"InjectZ"
RUNTIME_PYTHON=INJECTZ_DIR/"Runtime"/"python"/"bin"/"python3"
RENDER_SCRIPT=INJECTZ_DIR/"injectz_sharp_render.py"
SHARP_CHECKPOINT=INJECTZ_DIR/"Models"/"SHARP"/"sharp_2572gikvuh.pt"
CACHE_DIR=INJECTZ_DIR/"cache"/"sharp"
TORCH_EXTENSIONS_DIR=INJECTZ_DIR/"Runtime"/"torch_extensions"
PRESETS={"low":0.010,"medium":0.020,"strong":0.040,"very-strong":0.060}

def die(s): raise SystemExit("InjectZ error: "+s)

def run(cmd,env=None):
    print("\n> "+" ".join(map(str,cmd)))
    r=subprocess.run(list(map(str,cmd)),env=env)
    if r.returncode: die(f"command failed ({r.returncode})")

def main():
    p=argparse.ArgumentParser(description="InjectZ Engine v0.2.5 — portable SHARP stereo converter")
    p.add_argument("photo",type=Path)
    p.add_argument("--format",choices=["parallel","crossview"],default="parallel")
    p.add_argument("--depth",choices=list(PRESETS),default="medium")
    p.add_argument("--baseline",type=float)
    p.add_argument("--keep-eyes",action="store_true")
    p.add_argument("--allow-window-violations",action="store_true")
    p.add_argument("--eye-width",type=int,default=None,
                   help="Optional per-eye width override. Default preserves source dimensions.")
    p.add_argument("--output-dir",type=Path,default=None)
    p.add_argument("--rebuild",action="store_true")
    a=p.parse_args()

    photo=a.photo.expanduser().resolve()
    if not photo.is_file(): die(f"photo not found: {photo}")
    if not RUNTIME_PYTHON.is_file(): die(f"portable Python runtime not found: {RUNTIME_PYTHON}")
    if not RENDER_SCRIPT.is_file(): die(f"renderer helper not found: {RENDER_SCRIPT}")
    if not SHARP_CHECKPOINT.is_file(): die(f"SHARP checkpoint not found: {SHARP_CHECKPOINT}")

    baseline=a.baseline if a.baseline is not None else PRESETS[a.depth]
    if baseline<=0: die("baseline must be greater than zero")
    out=a.output_dir.expanduser().resolve() if a.output_dir is not None else photo.parent
    out.mkdir(parents=True,exist_ok=True)
    CACHE_DIR.mkdir(parents=True,exist_ok=True)
    TORCH_EXTENSIONS_DIR.mkdir(parents=True,exist_ok=True)
    ply=CACHE_DIR/f"{photo.stem}.ply"

    print("\nInjectZ Engine v0.2.5")
    print(f"Photo: {photo.name}\nEngine: SHARP 3DGS\nBaseline: {baseline:.4f}\nFormat: {a.format}\nOutput: {out}")

    env=os.environ.copy()
    env["TORCH_EXTENSIONS_DIR"]=str(TORCH_EXTENSIONS_DIR)

    if a.rebuild or not ply.exists():
        work=CACHE_DIR/f".work_{photo.stem}"
        shutil.rmtree(work,ignore_errors=True); work.mkdir()
        code="from sharp.cli import main_cli; main_cli()"
        run([RUNTIME_PYTHON,"-c",code,"--","predict","-i",photo,"-o",work,
             "-c",SHARP_CHECKPOINT,"--device","mps","--no-render"],env)
        made=work/f"{photo.stem}.ply"
        if not made.exists():
            c=list(work.glob("*.ply"))
            if len(c)!=1: die("could not locate SHARP PLY")
            made=c[0]
        if ply.exists(): ply.unlink()
        shutil.move(str(made),str(ply)); shutil.rmtree(work,ignore_errors=True)
    else:
        print(f"Reusing cached reconstruction: {ply.name}")

    lock=TORCH_EXTENSIONS_DIR/"metal_gauss_metal"/"lock"
    if lock.exists():
        try: lock.unlink()
        except OSError: pass

    cmd=[RUNTIME_PYTHON,RENDER_SCRIPT,"--photo",photo,"--ply",ply,
         "--baseline",str(baseline),"--format",a.format,
         "--output-dir",out]
    if a.eye_width is not None:
        cmd.extend(["--eye-width",str(a.eye_width)])
    if a.keep_eyes: cmd.append("--keep-eyes")
    if a.allow_window_violations: cmd.append("--allow-window-violations")
    run(cmd,env)
    print("\nInjectZ conversion complete.")

if __name__=="__main__":
    main()
