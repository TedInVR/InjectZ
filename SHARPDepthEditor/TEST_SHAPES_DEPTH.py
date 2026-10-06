import numpy as np
from shape_weights import shaped_mask,validate_shape
from depth_display import visible_inverse,shared_scale
m=np.ones((101,101),np.float32);m[:10]=0
s=shaped_mask(m,dict(mode='gradient',start=[0,.5],end=[1,.5]))
assert s[50,0]==0 and s[50,100]==1 and abs(s[50,50]-.5)<1e-6
r=shaped_mask(m,dict(mode='rounded',start=[.5,.5],end=[1,.5]))
assert r[50,50]==1 and r[50,100]==0 and 0<r[50,75]<1
f=shaped_mask(m,dict(feather=5));assert np.all(f[:10]==0) and f[10,50]==0 and f[20,50]==1
for bad in [dict(mode='invalid'),dict(feather=-1),dict(mode='gradient',start=[.5,.5],end=[.5,.5])]:
 try:validate_shape(bad)
 except ValueError:pass
 else:raise AssertionError('Invalid shape accepted')
x=np.arange(1,102,dtype=float).reshape(1,101);coverage=np.ones_like(x)
a,b,legend=shared_scale(x,x,coverage,coverage);assert np.array_equal(a,b)
_,far,_=shared_scale(x,x*.5,coverage,coverage);assert far.mean()<a.mean()
d,c=visible_inverse(np.array([[2.]]),np.array([[.5]]));assert d.item()==4
plane,c=visible_inverse(np.array([[2.]]),np.array([[.5]]),6);assert plane.item()==5
print('PASS: directional/rounded weights, inward-only feather, validation, common depth scale and alpha/plane composition.')
