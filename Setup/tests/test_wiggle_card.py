"""Test post-render stereo-card framing without a GPU or macOS."""
import sys
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'Reframe'))
from SharedStereoFormats import finish_stereo_card

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
print('Wiggle card background, arch, optional caption area and source preservation passed.')
