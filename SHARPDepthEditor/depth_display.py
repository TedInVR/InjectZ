import numpy as np

def visible_inverse(rgb,alpha,plane=None):
 a=np.asarray(alpha).squeeze();r=np.asarray(rgb)
 if plane is not None:return r+(1-a)*plane,np.ones_like(a)
 return np.divide(r,a,out=np.zeros_like(r),where=a>1e-5),a

def shared_scale(before,after,coverage,after_coverage):
 valid=(coverage>.1)&np.isfinite(before)&(before>0)
 if not valid.any():raise ValueError('No visible depth to display.')
 lo,hi=np.percentile(before[valid],[2,98]);hi=max(hi,lo+max(abs(lo)*.001,1e-8))
 def gray(d,c):return np.where((c>1e-5)&np.isfinite(d),np.clip((d-lo)/(hi-lo),0,1)*255,0).astype('uint8')
 return gray(before,coverage),gray(after,after_coverage),dict(far_inverse=float(lo),near_inverse=float(hi),note='White is nearer; black is farther or uncovered. Shared original scale; extremes clipped. Visible splats blend at edges; hidden surfaces are not shown.')
