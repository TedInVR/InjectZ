from PIL import Image
import numpy as np
from manual_mask import apply_strokes

base=Image.new('L',(100,80),255)
exclude={'shape':'rectangle','kind':'exclude','points':[[10,10],[35,25]]}
result=np.array(apply_strokes(base,[exclude]))
assert np.all(result[10:26,10:36]==0)
assert np.all(result[40:,:]==255)
# A correction to the lettering must not change a distant propeller pixel.
base_array=np.array(base);base_array[65,80]=0
base=Image.fromarray(base_array)
result=np.array(apply_strokes(base,[exclude]))
assert result[65,80]==0
# Full-rectangle exclusions stay excluded even after global classifier flips.
new_auto=Image.new('L',(100,80),255)
assert np.all(np.array(apply_strokes(new_auto,[exclude]))[10:26,10:36]==0)
# Continuous strokes cover the gaps between pointer events.
brush={'shape':'brush','kind':'exclude','radius':3,'points':[[50,40],[80,40]]}
result=np.array(apply_strokes(new_auto,[brush]))
assert np.all(result[40,50:81]==0)
assert result[10,50]==255
# Most recent edit wins; undo is exact replay without the last edit.
include={'shape':'rectangle','kind':'include','points':[[15,15],[20,20]]}
result=np.array(apply_strokes(new_auto,[exclude,include]))
assert result[17,17]==255 and result[12,12]==0
assert np.array(apply_strokes(new_auto,[exclude]))[17,17]==0
# Untouched pixels remain bit-identical.
original=np.arange(8000,dtype=np.uint8).reshape(80,100)
result=np.array(apply_strokes(Image.fromarray(original),[exclude]))
outside=np.ones((80,100),bool);outside[10:26,10:36]=False
assert np.array_equal(result[outside],original[outside])
print('PASS: local-only edits, full-region locks, continuous brush, ordered overrides, undo, unchanged pixels.')
