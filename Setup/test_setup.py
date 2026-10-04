import hashlib
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('setup_worker', Path(__file__).with_name('install_new.py'))
worker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(worker)

class SetupTests(unittest.TestCase):
    def test_existing_installation_is_untouched(self):
        with tempfile.TemporaryDirectory() as temporary:
            home = Path(temporary)
            root = home / 'InjectZ'
            root.mkdir()
            sentinel = root / 'InjectZ.swift'
            sentinel.write_text('KEEP MY APP')
            with patch.object(Path, 'home', return_value=home), patch('sys.argv', ['install_new.py', '--repo', temporary, '--iw3-python', '/unused', '--sharp', 'no']):
                with self.assertRaisesRegex(RuntimeError, 'Existing'):
                    worker.main()
            self.assertEqual(sentinel.read_text(), 'KEEP MY APP')
            self.assertEqual(list(root.iterdir()), [sentinel])

    def test_model_hash_must_match_before_install(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'download'
            source.write_bytes(b'checkpoint fixture')
            target = root / 'model.pt'
            with self.assertRaisesRegex(RuntimeError, 'checksum mismatch'):
                worker.download_verified(source.as_uri(), target, '0' * 64)
            self.assertFalse(target.exists())
            target.with_suffix('.pt.partial').unlink()
            worker.download_verified(source.as_uri(), target, hashlib.sha256(source.read_bytes()).hexdigest())
            self.assertEqual(target.read_bytes(), source.read_bytes())

if __name__ == '__main__':
    unittest.main()
