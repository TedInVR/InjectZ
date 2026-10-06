"""Test stereo alignment, alpha compositing and protected source pixels.

These tests do not claim LaMa/Metal execution or real-image quality validation.
"""
import numpy as np
from background_repair import composite, preserve_known, warp_background

background=np.zeros((4,20,3),np.float32)
background[:,10,:]=1
left=warp_background(background,100,10,10,-.1,10)
right=warp_background(background,100,10,10,.1,10)
assert left[0,:,0].argmax()==11
assert right[0,:,0].argmax()==9
# Convergence shift and eye translation must both participate.
assert warp_background(background,100,10,8,-.1,10)[0,:,0].argmax()==9
assert np.array_equal(warp_background(background,100,10,10,0,10),background)

bg=np.full((3,4,3),.7,np.float32)
fg=np.zeros_like(bg);alpha=np.zeros((3,4),np.float32)
alpha[1,1]=1;fg[1,1]=[.1,.2,.3]
result=composite(fg,alpha,bg)
assert np.array_equal(result[1,1],fg[1,1])
assert np.allclose(result[0,0],bg[0,0])
alpha[1,2]=.5;fg[1,2]=[.1,.2,.3]
assert np.allclose(composite(fg,alpha,bg)[1,2],fg[1,2]+bg[1,2]*.5)
assert np.array_equal(composite(fg,alpha[...,None],bg),composite(fg,alpha,bg))

source=np.arange(36,dtype=np.uint8).reshape(3,4,3)
generated=np.full_like(source,99);hole=np.zeros((3,4),bool);hole[1,1]=True
repaired=preserve_known(source,generated,hole)
assert np.array_equal(repaired[~hole],source[~hole])
assert np.array_equal(repaired[hole],generated[hole])
try:warp_background(background,100,10,10,0,0)
except ValueError:pass
else:raise AssertionError('Invalid depth was accepted')
print('PASS: shared background stereo alignment, alpha compositing, known-pixel protection.')
