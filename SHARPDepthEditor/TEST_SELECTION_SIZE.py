from PIL import Image
import numpy as np
from manual_mask import resize_selection
mask=np.zeros((50,70),np.uint8);mask[5:20,5:20]=255;mask[25:45,40:60]=255
image=Image.fromarray(mask)
small=np.array(resize_selection(image,-2));large=np.array(resize_selection(image,2))
assert small[7:18,7:18].all() and not small[5,5]
assert small[27:43,42:58].all() and not small[25,40]
assert large[3,3]==255 and large[23,38]==255
assert small.sum()<mask.sum()<large.sum()
assert np.array_equal(np.array(resize_selection(image,0)),mask)
assert np.array_equal(np.array(image),mask)
# The API applies each setting to this unchanged baseline, not previous result.
assert np.array(resize_selection(image,-3)).sum()>np.array(resize_selection(resize_selection(image,-2),-3)).sum()
try:resize_selection(image,21)
except ValueError:pass
else:raise AssertionError('Out-of-range value accepted')
print('PASS: shrink/expand all disconnected patches, exact reset, unchanged baseline, non-compounding values.')
