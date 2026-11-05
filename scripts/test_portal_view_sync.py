"""The maintainer sync detects drift and repairs only its owned helpers."""
import importlib.util
from pathlib import Path
import tempfile
import unittest


spec = importlib.util.spec_from_file_location(
    'download_sync', Path(__file__).with_name('sync-portal-view-downloads.py'))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class DownloadSyncTests(unittest.TestCase):
    def test_check_and_write_detect_and_repair_drift(self):
        source = Path(__file__).with_name('portal_view_release.py').read_text()
        support = Path(__file__).with_name(sync.SUPPORT).read_bytes()
        with tempfile.TemporaryDirectory() as temporary:
            workspace = Path(temporary)
            for repo in ('portal-config-loc', *sync.REPOS):
                scripts = workspace / repo / 'scripts'
                scripts.mkdir(parents=True)
                (scripts / 'portal_view_release.py').write_text(source + '\n# repo-local tail\n')
                (scripts / sync.SUPPORT).write_bytes(support)
            self.assertEqual(sync.synchronize(workspace), [])
            target = workspace / sync.REPOS[0] / 'scripts/portal_view_release.py'
            changed = target.read_text().replace('portal-view-release/1.0', 'old-client/1.0')
            target.write_text(changed)
            fixture = target.with_name(sync.SUPPORT)
            fixture.write_bytes(b'outdated fixture')
            self.assertEqual(len(sync.synchronize(workspace)), 2)
            self.assertEqual(target.read_text(), changed)  # Check is read-only.
            sync.synchronize(workspace, write=True)
            self.assertEqual(sync.synchronize(workspace), [])
            self.assertTrue(target.read_text().endswith('# repo-local tail\n'))
            target.write_text(target.read_text().replace(
                '    downloader = download_batch(source, downloader)\n', '    pass\n'))
            with self.assertRaisesRegex(ValueError, 'stage admission'):
                sync.synchronize(workspace)
