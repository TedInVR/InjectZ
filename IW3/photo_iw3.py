"""Inject Z-only IW3 entry point: protect depth at all four image borders."""
import inspect, math, os, sys, textwrap

def border_convergence(depth, current, strength):
    import torch
    if depth.ndim != 4 or not torch.isfinite(depth).all():
        raise ValueError('Cannot protect stereo window: invalid mapped depth tensor')
    b, c, h, w = depth.shape
    # Include a strip wide enough to cover possible horizontal displacement,
    # plus a small top/bottom strip; do not inspect the interior foreground.
    sx=min(w,max(2,math.ceil(max(w,h)*abs(float(strength))*.02)+2))
    sy=min(h,max(2,math.ceil(h*.005)))
    edges=torch.cat((depth[:,:,:,:sx].flatten(1),depth[:,:,:,-sx:].flatten(1),
                     depth[:,:,:sy,:].flatten(1),depth[:,:,-sy:,:].flatten(1)),dim=1)
    safe=edges.max(dim=1).values.reshape(b,1,1,1)+0.002
    existing=torch.as_tensor(current,dtype=depth.dtype,device=depth.device)
    if existing.numel()==b: existing=existing.reshape(b,1,1,1)
    return torch.maximum(safe,existing)

def install_guard(utils):
    source=textwrap.dedent(inspect.getsource(utils.apply_divergence))
    anchor='    if args.method == "NULL":'
    if source.count(anchor)!=1 or 'depth = get_mapper(args.mapper)(depth)' not in source:
        raise RuntimeError('Installed IW3 stereo code differs; four-edge protection cannot be applied safely')
    source=source.replace(anchor,'    convergence = _injectz_border_convergence(depth, convergence, args.divergence)\n'+anchor,1)
    namespace=dict(utils.apply_divergence.__globals__)
    namespace['_injectz_border_convergence']=border_convergence
    exec(compile(source,'<Inject Z four-edge convergence>','exec'),namespace)
    utils.apply_divergence=namespace['apply_divergence']

if __name__=='__main__':
    protected='--injectz-protect-window' in sys.argv
    if protected: sys.argv.remove('--injectz-protect-window')
    sys.path.insert(0, os.getcwd())
    import iw3.utils as utils
    if protected:
        install_guard(utils)
        print('Inject Z: four-edge depth-based window protection enabled.',flush=True)
    from iw3.cli import main
    main()
