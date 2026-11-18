"""Check built-in app descriptions remain wired to the not-found dialog."""
from pathlib import Path

source = (Path(__file__).resolve().parents[2] / 'App/InjectZ.swift').read_text()
builtins = source.split('let builtins:', 1)[1].split('for (name, names, link) in builtins', 1)[0]
descriptions = source.split('func showRelatedAppDescription', 1)[1].split('func locateBuiltInApp', 1)[0]
for name in ("Ted's Video Tool", 'StereoMask for Mac', 'VM ReSizer', 'Stereo Slideshow'):
    assert f'"{name}"' in builtins and f'"{name}"' in descriptions, name
dialog = source.split('@objc func openRelatedApp', 1)[1].split('func showRelatedAppDescription', 1)[0]
buttons = ['Download from GitHub', 'Navigate to it', 'What is \\(id)?', 'OK']
offsets = [dialog.index(f'alert.addButton(withTitle: "{name}")') for name in buttons]
assert offsets == sorted(offsets)
assert 'choice == .alertThirdButtonReturn { showRelatedAppDescription(id); continue }' in dialog
assert 'choice == .alertSecondButtonReturn { locateBuiltInApp(id) }' in dialog
assert 'choice == .alertFirstButtonReturn' in dialog
print('All four app descriptions and existing download/locate dialog actions are wired.')
