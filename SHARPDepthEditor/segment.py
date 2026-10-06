import json,sys
import numpy as np
from PIL import Image
import cv2
photo,spec,out=sys.argv[1:]
s=json.load(open(spec))
im=np.array(Image.open(photo).convert('RGB'))
h,w=im.shape[:2]
r=[int(v) for v in s['rect']]
x,y,rw,rh=r
if x<0 or y<0 or rw<4 or rh<4 or x+rw>w or y+rh>h:raise ValueError('Draw a box around the object, leaving some background outside the box.')
mask=np.zeros((h,w),np.uint8);mask[y:y+rh,x:x+rw]=cv2.GC_PR_FGD
for point in s.get('points',[]):
 px,py,kind=point
 cv2.circle(mask,(int(px),int(py)),max(3,round(min(w,h)*.008)),cv2.GC_FGD if kind=='fg' else cv2.GC_BGD,-1)
bgd=np.zeros((1,65));fgd=np.zeros((1,65))
cv2.grabCut(im,mask,None,bgd,fgd,5,cv2.GC_INIT_WITH_MASK)
result=np.where((mask==1)|(mask==3),255,0).astype(np.uint8)
for px,py,kind in s.get('points',[]):
 cv2.circle(result,(int(px),int(py)),max(3,round(min(w,h)*.008)),255 if kind=='fg' else 0,-1)
Image.fromarray(result).save(out)
