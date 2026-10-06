import numpy as np
from scipy.ndimage import distance_transform_edt

def validate_shape(data):
 mode=data.get('mode','uniform')
 if mode not in ('uniform','gradient','rounded'):raise ValueError('Unknown depth shape.')
 feather=float(data.get('feather',0))
 if not np.isfinite(feather) or not 0<=feather<=100:raise ValueError('Feather must be 0–100 selection pixels.')
 a=np.asarray(data.get('start',[.25,.5]),float);b=np.asarray(data.get('end',[.75,.5]),float)
 if a.shape!=(2,) or b.shape!=(2,) or not np.isfinite([a,b]).all() or (a<0).any() or (a>1).any() or (b<0).any() or (b>1).any():raise ValueError('Invalid shape handles.')
 if mode!='uniform' and np.linalg.norm(b-a)<.0001:raise ValueError('Drag a longer shape guide.')
 return dict(mode=mode,feather=feather,start=a.tolist(),end=b.tolist())

def shaped_mask(mask,data):
 s=validate_shape(data);m=np.clip(np.asarray(mask,dtype=np.float32),0,1);h,w=m.shape
 y,x=np.mgrid[:h,:w];a=np.array(s['start'])*[w-1,h-1];b=np.array(s['end'])*[w-1,h-1];v=b-a
 if s['mode']=='gradient':weight=np.clip(((x-a[0])*v[0]+(y-a[1])*v[1])/np.dot(v,v),0,1)
 elif s['mode']=='rounded':
  t=np.clip(np.hypot(x-a[0],y-a[1])/np.linalg.norm(v),0,1);weight=(1-t*t)**2
 else:weight=np.ones_like(m)
 if s['feather']:
  # Padding makes the image boundary a real mask edge. Never grow outside it.
  d=distance_transform_edt(np.pad(m>0,1))[1:-1,1:-1];t=np.clip((d-1)/s['feather'],0,1);weight*=t*t*(3-2*t)
 return (m*weight).astype(np.float32)
