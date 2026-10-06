# Executed inside a COPY of the installed renderer after source intrinsics exist.
import json as _json, os as _os
from geometry import ray_move
from shape_weights import shaped_mask
from scipy.ndimage import gaussian_filter, map_coordinates
_spec=_json.loads(_os.environ['INJECTZ_GUIDED_SPEC'])
_original=sp.means.detach().cpu().numpy().copy()
_z=_original[:,2]
_valid=np.isfinite(_original).all(axis=1)&(_z>0)
_uv=np.zeros((len(_original),2))
_uv[_valid,0]=float(K[0,0])*_original[_valid,0]/_z[_valid]+float(K[0,2])
_uv[_valid,1]=float(K[1,1])*_original[_valid,1]/_z[_valid]+float(K[1,2])
_original_scales=sp.scales.clone()
_original_opacities=sp.opacities.clone()
_positions=_original.copy()
_scale=np.ones(len(_original),np.float32)
for _region in _spec:
    with Image.open(_region['mask']) as _im:
        _selection_width=_im.width
        _mask=np.array(_im.resize((W,H),Image.Resampling.BILINEAR),dtype=np.float32)/255
    _mask=shaped_mask(_mask,dict(_region.get('shape',{}),feather=float(_region.get('shape',{}).get('feather',0))*W/_selection_width))
    _weights=map_coordinates(_mask,[_uv[:,1],_uv[:,0]],order=1,mode='constant',cval=0)
    _weights[~_valid]=0
    _positions,_factor=ray_move(_positions,_weights,float(_region['amount']))
    _scale*=_factor
with torch.no_grad():
    sp.means.copy_(torch.as_tensor(_positions,device=sp.means.device,dtype=sp.means.dtype))
    sp.scales.mul_(torch.as_tensor(_scale[:,None],device=sp.scales.device,dtype=sp.scales.dtype))
positive_z=sp.means[:,2]
positive_z=positive_z[torch.isfinite(positive_z)&(positive_z>0)]
injectz_far_clip=max(100.0,float(positive_z.max())*1.1+1,float(_z[_valid].max())*1.1+1)
print('Applied guided depth regions:',len(_spec),flush=True)

if _os.environ.get('INJECTZ_REPAIR_BACKGROUND') or _os.environ.get('INJECTZ_DEPTH_REPAIR'):
    from background_repair import warp_background, composite
    # Repair mode is deliberately limited to one farther-away sky region.
    _sky_region = next(r for r in _spec if r.get('role')=='background')
    with Image.open(_sky_region['mask']) as _im:
        _sky_mask = np.asarray(_im.convert('L').resize((W,H),Image.Resampling.BILINEAR),dtype=np.float32)/255
    _sky_weight = map_coordinates(_sky_mask,[_uv[:,1],_uv[:,0]],order=1,mode='constant',cval=0)
    _sky_selected = _valid & (_sky_weight >= .5)
    _foreground_selected = _valid & ~_sky_selected
    if not _sky_selected.any() or not _foreground_selected.any():
        raise RuntimeError('No usable foreground/background geometry for repair.')
    _background_z = max(float(np.median(_positions[_sky_selected,2])),
                        float(np.percentile(_positions[_foreground_selected,2],99))*1.02)
    _source_cx = float(K[0,2])
    if _os.environ.get('INJECTZ_REPAIR_BACKGROUND'):
        with Image.open(_os.environ['INJECTZ_REPAIR_BACKGROUND']) as _im:
            _shared_background = np.asarray(_im.convert('RGB').resize((W,H),Image.Resampling.LANCZOS),dtype=np.float32)/255
    # Remove the old selected sky; foreground geometry/colors remain SHARP.
    with torch.no_grad():
        sp.opacities[torch.as_tensor(_sky_selected,device=sp.opacities.device,dtype=torch.bool)] = 0
    def render_frames_with_scene_distance(sp, views, K, W, H, background, backend):
        from metal_gauss.api import render as render_splats
        for vm in views:
            rgb, alpha, _ = render_splats(sp.means,sp.quats,sp.scales,sp.opacities,sp.sh,
                K,vm,W,H,sh_degree=sp.sh_degree,backend=backend,
                background=(0.,0.,0.),far=injectz_far_clip)
            _camera_x = -float(vm[0,3])
            _back = warp_background(_shared_background,float(K[0,0]),_source_cx,float(K[0,2]),_camera_x,_background_z)
            _composed = composite(rgb.detach().cpu().numpy(),alpha.detach().cpu().numpy(),_back)
            yield torch.as_tensor(_composed,device=rgb.device,dtype=rgb.dtype)
    print('Shared repaired background plane depth:',_background_z,flush=True)

if _os.environ.get('INJECTZ_DEPTH_OUTPUT'):
    from metal_gauss.api import render as _render_depth
    from depth_display import visible_inverse, shared_scale
    def _depth(means,scales,opacities,plane=None):
        zz=means[:,2]
        inv=torch.where(torch.isfinite(zz)&(zz>0),1/zz.clamp(min=1e-8),torch.zeros_like(zz))
        colors=inv[:,None].expand(-1,3).contiguous()
        rgb,alpha,_=_render_depth(means,sp.quats,scales,opacities,sp.sh,K,
            torch.eye(4,device=means.device),W,H,colors=colors,sh_degree=sp.sh_degree,
            backend='metal',background=(0.,0.,0.),far=injectz_far_clip)
        return visible_inverse(rgb.detach().cpu().numpy()[...,0],alpha.detach().cpu().numpy(),plane)
    _before,_coverage=_depth(torch.as_tensor(_original,device=sp.means.device,dtype=sp.means.dtype),_original_scales,_original_opacities)
    _after,_after_coverage=_depth(sp.means,sp.scales,sp.opacities,1/_background_z if _os.environ.get('INJECTZ_DEPTH_REPAIR') else None)
    _a,_b,_legend=shared_scale(_before,_after,_coverage,_after_coverage)
    _folder=Path(_os.environ['INJECTZ_DEPTH_OUTPUT'])
    Image.fromarray(_a).save(_folder/'depth-original.png');Image.fromarray(_b).save(_folder/'depth-adjusted.png')
    (_folder/'depth-legend.json').write_text(_json.dumps(_legend))
    raise SystemExit(0)
