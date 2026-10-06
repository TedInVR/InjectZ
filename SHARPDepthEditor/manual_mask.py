"""Deterministic local mask edits. Later strokes take precedence."""
from PIL import Image, ImageDraw
import math

def resize_selection(mask, pixels):
    """Square morphological margin, applied once to the un-resized draft."""
    from PIL import ImageFilter
    if not isinstance(pixels,int) or not -20<=pixels<=20:
        raise ValueError('Selection size must be a whole number from -20 to 20.')
    result=mask.convert('L').copy()
    if pixels:
        size=2*abs(pixels)+1
        result=result.filter(ImageFilter.MaxFilter(size) if pixels>0 else ImageFilter.MinFilter(size))
    return result

def apply_strokes(base, strokes):
    result=base.convert('L').copy()
    draw=ImageDraw.Draw(result)
    w,h=result.size
    for stroke in strokes:
        value=255 if stroke['kind']=='include' else 0
        if stroke['kind'] not in ('include','exclude'):
            raise ValueError('Unknown selection edit.')
        points=stroke.get('points',[])
        if not points or len(points)>5000:
            raise ValueError('Invalid stroke length.')
        points=[tuple(float(v) for v in p) for p in points]
        if any(len(p)!=2 or not all(math.isfinite(v) for v in p) for p in points):
            raise ValueError('Invalid coordinates.')
        points=[(max(0,min(w-1,x)),max(0,min(h-1,y))) for x,y in points]
        if stroke.get('shape')=='rectangle':
            if len(points)!=2:raise ValueError('Rectangle needs two corners.')
            x1,y1=points[0];x2,y2=points[1]
            draw.rectangle((min(x1,x2),min(y1,y2),max(x1,x2),max(y1,y2)),fill=value)
        else:
            radius=float(stroke.get('radius',8))
            if not math.isfinite(radius) or not 1<=radius<=100:raise ValueError('Brush radius must be 1–100.')
            if len(points)>1:draw.line(points,fill=value,width=max(1,round(radius*2)))
            for x,y in points:draw.ellipse((x-radius,y-radius,x+radius,y+radius),fill=value)
    return result
