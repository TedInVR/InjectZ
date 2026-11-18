"""Test post-render stereo-card framing without a GPU or macOS."""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

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
print('Wiggle card background, arch, optional caption area and source preservation passed.')
