"""Exercise actual imported stereo exports without a Mac or a model."""
import subprocess
import sys
import tempfile
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[2]
helper = root / 'Reframe/SharedStereoFormats.py'

with tempfile.TemporaryDirectory() as tmp:
    d = Path(tmp)
    l = Image.new('RGB', (40, 30), (240, 0, 0))
    r = Image.new('RGB', (40, 30), (0, 0, 240))
    l.save(d / 'left.png'); r.save(d / 'right.png')
    sbs = Image.new('RGB', (80, 30)); sbs.paste(r, (0, 0)); sbs.paste(l, (40, 0)); sbs.save(d / 'cross.png')
    for suffix, inputs in [('cross', [d/'cross.png', '--input-format', 'crossview']),
                           ('eyes', [d/'left.png', '--input-format', 'eyes', '--right-eye', d/'right.png'])]:
        subprocess.run([sys.executable, str(helper), *map(str, inputs), '--output-prefix', str(d/suffix),
                        '--depth-token', 'test', '--formats', 'Parallel', 'LeftEye', 'RightEye'], check=True)
        with Image.open(d / (suffix + '_Parallel_Depthtest.png')) as im:
            assert im.getpixel((20, 15)) == (240, 0, 0)
            assert im.getpixel((60, 15)) == (0, 0, 240)
        with Image.open(d / (suffix + '_LeftEye_Depthtest.png')) as im:
            assert im.size == (40, 30) and im.getpixel((20, 15)) == (240, 0, 0)
    Image.new('RGB', (39, 30)).save(d/'mismatch.png')
    result = subprocess.run([sys.executable, str(helper), str(d/'left.png'), '--input-format', 'eyes',
                             '--right-eye', str(d/'mismatch.png'), '--output-prefix', str(d/'bad'),
                             '--depth-token', 'test', '--formats', 'Parallel'], capture_output=True)
    assert result.returncode != 0 and b'identical dimensions' in result.stderr
    assert (d/'left.png').is_file() and (d/'right.png').is_file()
print('Imported stereo order, eye exports, mismatch rejection and source preservation passed.')
