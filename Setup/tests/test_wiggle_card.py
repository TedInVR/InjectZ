"""Test post-render stereo-card framing without a GPU or macOS."""
import sys
import subprocess
import tempfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'Reframe'))
from SharedStereoFormats import finish_stereo_card, fit_card_caption

source = Image.new('RGB', (400, 300), (10, 130, 240))
original = source.tobytes()
framed = finish_stereo_card(source, '#C68833', 'Historic view')
assert source.tobytes() == original
assert framed.width % 2 == framed.height % 2 == 0
assert framed.getpixel((0, 0)) == (198, 136, 51)
assert framed.getpixel((12, 12)) == (198, 136, 51)
assert framed.getpixel((200, 150)) == (10, 130, 240)
plain = finish_stereo_card(source, '#000000', '')
assert plain.getpixel((0, 0)) == (0, 0, 0)
assert plain.height < framed.height
border = round(min(source.size) * .025)
assert plain.height - source.height - border in (border, border + 1)
assert framed.height - source.height - border in (45, 46)
draw = ImageDraw.Draw(framed)
long_title = 'A historic expedition through the beautiful mountain landscape'
text, font, spacing, bounds = fit_card_caption(draw, long_title, 320, 33, 17)
assert len(text.splitlines()) == 2, text
assert bounds[2] - bounds[0] <= 320 and bounds[3] - bounds[1] <= 33
framed_long = finish_stereo_card(source, '#C68833', long_title)
assert framed_long.size == framed.size
word, _, _, word_bounds = fit_card_caption(draw, 'Pneumonoultramicroscopicsilicovolcanoconiosis', 180, 33, 17)
assert len(word.splitlines()) <= 2 and word_bounds[2] - word_bounds[0] <= 180

with tempfile.TemporaryDirectory() as tmp:
    d = Path(tmp)
    left = Image.new('RGB', (400, 300), (240, 20, 30))
    right = Image.new('RGB', (400, 300), (10, 120, 240))
    sbs = Image.new('RGB', (800, 300)); sbs.paste(left, (0, 0)); sbs.paste(right, (400, 0))
    sbs.save(d/'input.png')
    helper = root/'Reframe/SharedStereoFormats.py'
    subprocess.run([sys.executable, str(helper), str(d/'input.png'), '--output-prefix', str(d/'test'),
                    '--depth-token', 'x', '--card-color', '#C68833', '--card-title', long_title,
                    '--formats', 'Parallel', 'Crossview', 'LeftEye', 'RightEye', 'Anaglyph_Dubois'], check=True)
    with Image.open(d/'test_Parallel_Depthx.png') as p, Image.open(d/'test_Crossview_Depthx.png') as c:
        w = p.width // 2
        # The whole caption strip is exactly equal in both eyes and formats.
        top = border + source.height
        region = (0, top, w, p.height)
        assert ImageChops.difference(p.crop(region), p.crop((w, top, 2*w, p.height))).getbbox() is None
        assert ImageChops.difference(p.crop(region), c.crop(region)).getbbox() is None
    with Image.open(d/'test_Anaglyph_Dubois_Depthx.png') as a:
        assert a.getpixel((0, 0)) == (198, 136, 51)
    with Image.open(d/'test_LeftEye_Depthx.png') as l, Image.open(d/'test_RightEye_Depthx.png') as r:
        assert ImageChops.difference(l.crop((0, top, l.width, l.height)), r.crop((0, top, r.width, r.height))).getbbox() is None

    # Exercise the separate Apple Reframe route and its formatter arguments.
    work = d/'work'; (work/'Exports/RIGHT').mkdir(parents=True)
    left.save(d/'original.png'); right.save(work/'Exports/RIGHT/right.png')
    subprocess.run([sys.executable, str(root/'Reframe/FinishSingleRight.py'), str(work), str(d/'original.png'),
                    '--pan', '.04', '--allow-window-violations', '--card-color', '#C68833',
                    '--card-title', long_title, '--formats', 'Parallel'], check=True)
    with Image.open(d/'original_InjectZ_Reframe_Parallel_Depth0.0400.png') as reframe:
        assert reframe.getpixel((0, 0)) == (198, 136, 51)
print('Wiggle card background, arch, optional caption area and source preservation passed.')
