"""Prevent publishing stale sources or partial/mixed Godot exports."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from site_artifact import CRITICAL, verify


class ArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        files = {name: b'fixture' for name in CRITICAL}
        files['index.html'] = b'<script src="build-guard.mjs"></script><button id="classroomJoin">Classroom</button>'
        files['build-id.mjs'] = b'export const BUILD_ID="test-build";'
        files['onnx/runtime.wasm'] = b'\x00asm fixture'
        for name, data in files.items():
            p = self.root / name
            p.parent.mkdir(exist_ok=True)
            p.write_bytes(data)
        self.info = {'buildId': 'test-build', 'protocolVersion': 3, 'files': {
            name: {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()} for name, data in files.items()}}
        self.save()

    def tearDown(self):
        self.temp.cleanup()

    def save(self):
        (self.root / 'build-info.json').write_text(json.dumps(self.info))

    def test_complete_export(self):
        self.assertEqual(verify(self.root)['buildId'], 'test-build')

    def test_old_v2_folder_has_no_manifest(self):
        (self.root / 'build-info.json').unlink()
        with self.assertRaises(FileNotFoundError): verify(self.root)

    def test_mixed_pck_is_rejected(self):
        (self.root / 'index.pck').write_bytes(b'old V2 package')
        with self.assertRaises(ValueError): verify(self.root)

    def test_nested_dependency_is_required(self):
        (self.root / 'onnx/runtime.wasm').unlink()
        with self.assertRaises(FileNotFoundError): verify(self.root)

    def test_manifest_cannot_escape_artifact(self):
        self.info['files']['../outside'] = {'bytes': 0, 'sha256': ''}
        self.save()
        with self.assertRaises(ValueError): verify(self.root)

    def test_stale_source_is_rejected(self):
        self.info['source'] = {'digest': 'old'}
        self.save()
        with self.assertRaises(ValueError): verify(self.root, source=True)


if __name__ == '__main__':
    unittest.main()
