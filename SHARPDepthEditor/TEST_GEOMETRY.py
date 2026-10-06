import numpy as np
from geometry import ray_move
p=np.array([[1.,2.,10.],[2.,3.,20.],[3.,4.,30.]],dtype=np.float32)
a,s=ray_move(p,np.array([1.,1.,0.]),.3)
assert np.allclose(a[:,:2]/a[:,2,None],p[:,:2]/p[:,2,None])
assert np.all(a[:2,2]<p[:2,2])
assert np.array_equal(a[2],p[2])
assert np.allclose(np.diff(1/a[:2,2]),np.diff(1/p[:2,2]))
b,_=ray_move(p,np.array([1.,1.,0.]),-.3)
assert np.all(b[:2,2]>p[:2,2])
assert np.allclose(p,ray_move(p,np.ones(3),0)[0])
print('Ray projection, closer/farther, unselected preservation and inverse-depth structure tests passed.')
