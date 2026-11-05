"""Check drift refusal, diagnostics, and rollback without touching real checkouts."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    'download_sync', Path(__file__).with_name('sync-portal-view-downloads.py'))
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class DownloadSyncTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.workspace = Path(temporary.name)
        scripts = Path(__file__).parent
        self.source = (scripts / 'portal_view_release.py').read_text()
        for repo in ('portal-config-loc', *sync.REPOS):
            target = self.workspace / repo / 'scripts'
            target.mkdir(parents=True)
            (target / 'portal_view_release.py').write_text(self.source + '\n# repo-local tail\n')
            (target / sync.SUPPORT).write_bytes((scripts / sync.SUPPORT).read_bytes())
        sync.synchronize(self.workspace, write=True)
        self.target = self.workspace / sync.REPOS[0] / 'scripts/portal_view_release.py'

    def test_check_and_write_detect_and_repair_drift(self):
        self.assertEqual(sync.synchronize(self.workspace), [])
        changed = self.target.read_text().replace('portal-view-release/1.0', 'old-client/1.0')
        self.target.write_text(changed)
        fixture = self.target.with_name(sync.SUPPORT)
        fixture.write_bytes(b'outdated fixture')
        self.assertEqual(len(sync.synchronize(self.workspace)), 2)
        self.assertEqual(self.target.read_text(), changed)
        sync.synchronize(self.workspace, write=True)
        self.assertEqual(sync.synchronize(self.workspace), [])
        self.assertTrue(self.target.read_text().endswith('# repo-local tail\n'))

    def test_reverted_signature_is_refused_without_writes(self):
        self.target.write_text(self.target.read_text().replace(
            'key_dir, downloader=None)', 'key_dir, downloader=fetch)'))
        before = self.target.read_bytes()
        with self.assertRaisesRegex(ValueError, 'stage contract.*signature'):
            sync.synchronize(self.workspace, write=True)
        self.assertEqual(self.target.read_bytes(), before)

    def test_added_stage_docstring_does_not_shift_admission_check(self):
        self.target.write_text(self.target.read_text().replace(
            'key_dir, downloader=None):\n', 'key_dir, downloader=None):\n    """Stage documentation."""\n'))
        self.assertEqual(sync.synchronize(self.workspace), [])

    def test_body_bypass_is_refused(self):
        self.target.write_text(self.target.read_text().replace(
            '            transport = download_opener()\n', '            transport = None\n'))
        with self.assertRaisesRegex(ValueError, 'stage contract'):
            sync.synchronize(self.workspace)

    def test_invalid_python_and_missing_function_have_path_diagnostics(self):
        for text, message in (('def broken(', 'invalid Python'),
                              (self.source.replace('def fetch(', 'def missing_fetch('),
                               'required function fetch is missing')):
            self.target.write_text(text)
            with contextlib.redirect_stderr(io.StringIO()) as output:
                self.assertEqual(sync.main(['--workspace', str(self.workspace)]), 2)
            self.assertIn(str(self.target), output.getvalue())
            self.assertIn(message, output.getvalue())
            self.assertNotIn('Traceback', output.getvalue())

    def test_mid_publication_failure_restores_original_files(self):
        originals = {}
        for repo in sync.REPOS:
            target = self.workspace / repo / 'scripts' / sync.SUPPORT
            target.write_bytes(b'drift')
            originals[target] = target.read_bytes()
        replace, calls = os.replace, []

        def fail_once(source, destination):
            calls.append(destination)
            if len(calls) == 2:
                raise OSError('injected publication failure')
            return replace(source, destination)

        with patch.object(sync.os, 'replace', side_effect=fail_once):
            with self.assertRaisesRegex(OSError, 'injected publication failure'):
                sync.synchronize(self.workspace, write=True)
        for path, original in originals.items():
            self.assertEqual(path.read_bytes(), original)
        self.assertEqual(list(self.workspace.rglob('*.sync-*')), [])

    def test_failed_rollback_reports_and_retains_recovery_backup(self):
        originals = []
        for repo in sync.REPOS:
            target = self.workspace / repo / 'scripts' / sync.SUPPORT
            target.write_bytes(b'drift')
            originals.append(target)
        replace, count = os.replace, 0

        def fail_publication_and_rollback(source, destination):
            nonlocal count
            count += 1
            if count in (2, 3):
                raise OSError('injected filesystem failure')
            return replace(source, destination)

        with patch.object(sync.os, 'replace', side_effect=fail_publication_and_rollback):
            with self.assertRaisesRegex(RuntimeError, 'rollback incomplete.*backup='):
                sync.synchronize(self.workspace, write=True)
        backups = list(self.workspace.rglob('*.sync-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), b'drift')
        self.assertEqual(originals[1].read_bytes(), b'drift')
