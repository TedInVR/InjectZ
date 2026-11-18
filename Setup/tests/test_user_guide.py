"""Check the shipped and repository guides cover the current main workflows."""
from html.parser import HTMLParser
from pathlib import Path

root = Path(__file__).resolve().parents[2]
paths = [root/'Assets/InjectZ_User_Guide.html', root/'Docs/USER_GUIDE.md', root/'USER_GUIDE.md']
terms = ('Additional Export Options', 'Open an existing stereo image',
         'Multi-frame wigglegrams and PNG views', 'Stereo-card',
         'Save and recall presets', 'Open other apps from Inject Z',
         'Export all views as PNGs', 'What is', 'Navigate to it')
for path in paths:
    text = path.read_text()
    for term in terms:
        assert term.lower() in ' '.join(text.lower().split()), (path, term)

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids = set(); self.anchors = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs: self.ids.add(attrs['id'])
        if tag == 'a' and attrs.get('href', '').startswith('#'): self.anchors.append(attrs['href'][1:])

html = paths[0].read_text()
parser = Links(); parser.feed(html)
assert not (set(parser.anchors) - parser.ids), set(parser.anchors) - parser.ids
assert 'SHARP Manual Depth Editor' in html and 'Completion audio alerts' in html
assert 'SHARP Manual Depth Editor' in paths[1].read_text()
print('Bundled and repository guides cover the features and in-page links resolve.')
