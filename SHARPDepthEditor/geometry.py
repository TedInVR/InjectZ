import numpy as np

def ray_move(xyz, weights, amount):
    """Shift inverse depth relative to region median, retaining original rays."""
    xyz=np.asarray(xyz)
    weights=np.asarray(weights)
    good=np.isfinite(xyz).all(axis=1)&(xyz[:,2]>0)&(weights>0.01)
    scale=np.ones(len(xyz),dtype=xyz.dtype)
    if not good.any(): raise ValueError('Selected region contains no positive-depth splats.')
    median=np.median(1/xyz[good,2])
    inv=1/xyz[good,2]
    newinv=np.maximum(inv+amount*median*weights[good],inv/5)
    scale[good]=np.clip(inv/newinv,0.2,5)
    return xyz*scale[:,None],scale
