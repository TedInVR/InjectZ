"""Optional narrow, disparity-boundary-only softening for SHARP eyes."""
import math
import numpy as np
from scipy import ndimage
from PIL import Image, ImageFilter

def boundary_mask(disparity, valid, radius, threshold=1.5):
    d=np.asarray(disparity,dtype=np.float32)
    v=np.asarray(valid,dtype=bool)
    if d.ndim!=2 or d.shape!=v.shape:raise ValueError('Invalid disparity/mask dimensions')
    v=v & np.isfinite(d)
    seed=np.zeros(d.shape,dtype=bool)
    horizontal=v[:,1:] & v[:,:-1] & (np.abs(d[:,1:]-d[:,:-1])>=threshold)
    vertical=v[1:,:] & v[:-1,:] & (np.abs(d[1:,:]-d[:-1,:])>=threshold)
    seed[:,1:] |= horizontal;seed[:,:-1] |= horizontal
    seed[1:,:] |= vertical;seed[:-1,:] |= vertical
    if not seed.any():return np.zeros(d.shape,dtype=np.float32)
    # Compact support: no changes arbitrarily far from a depth boundary.
    distance=ndimage.distance_transform_edt(~seed)
    width=float(radius)
    mask=np.clip((width+0.5-distance)/max(width,0.5),0,1).astype(np.float32)
    mask[distance>width+0.5]=0
    mask[~v]=0
    return mask

def soften(image, mask, radius, strength):
    if not 0<=strength<=1 or not 0.5<=radius<=6:raise ValueError('Edge softening radius/strength out of range')
    if strength==0:return image.copy()
    image=image.convert('RGB')
    m=np.asarray(mask,dtype=np.float32)
    if m.shape!=(image.height,image.width):raise ValueError('Edge mask does not match eye image')
    amount=np.clip(m*strength,0,1)[:,:,None]
    original=np.asarray(image,dtype=np.float32)
    blurred=np.asarray(image.filter(ImageFilter.GaussianBlur(radius=radius)),dtype=np.float32)
    out=np.rint(original+(blurred-original)*amount).clip(0,255).astype(np.uint8)
    return Image.fromarray(out,'RGB')

def projected_mask(sp, view, K, W, H, baseline, far, radius):
    import torch
    from metal_gauss.api import render
    # Current eye cameras have identity rotation and horizontal translation.
    # Project inverse depth as splat color, then normalize by accumulated alpha.
    z=sp.means[:,2]
    inverse=torch.where(torch.isfinite(z) & (z>0),1/z.clamp_min(1e-6),torch.zeros_like(z))
    norm=inverse.max().clamp_min(1e-6)
    colors=(inverse/norm).unsqueeze(1).expand(-1,3).contiguous()
    with torch.no_grad():
        depth_rgb,alpha,_=render(sp.means,sp.quats,sp.scales,sp.opacities,sp.sh,
                               K,view,W,H,sh_degree=sp.sh_degree,backend='metal',
                               background=(0.,0.,0.),colors=colors,far=far)
        inverse_image=depth_rgb[...,0]/alpha.clamp_min(1e-6)*norm
        disparity=inverse_image*float(K[0,0])*abs(float(baseline))
        d=disparity.detach().cpu().numpy()
        valid=(alpha>.85).detach().cpu().numpy()
    return boundary_mask(d,valid,radius)
