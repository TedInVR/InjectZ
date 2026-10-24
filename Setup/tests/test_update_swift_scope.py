"""Regression for updater cleanup accidentally inserted into the Reframe dialog."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
source=(root/'App/InjectZ.swift').read_text()
updater=source.index('final class InjectZUpdates {')
assert 'self.execute(' not in source[:updater], 'Updater execution escaped its class'
assert '--discard-job' not in source[:updater], 'Updater cleanup escaped its class'
assert source[updater:].count('--discard-job')==2
assert 'guard confirm.runModal() == .alertFirstButtonReturn else { return }\n        guard checkReframePermission()' in source
manifest=json.loads((root/'Setup/UpdateManifest.json').read_text())
record=manifest['files']['App/InjectZ.swift']
assert record['algorithm']=='sha256'
assert record['digest']==hashlib.sha256((root/'App/InjectZ.swift').read_bytes()).hexdigest()
print('Swift updater scope and Reframe cancellation regression passed; source checksum matches.')
