#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('admission', Path(__file__).resolve().parents[1] / 'scripts/sync-personal-runner-admission.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class AdmissionTest(unittest.TestCase):
    def test_unenrolled_and_incomplete_enrollment(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'property_value', return_value='not-found'):
            root = Path(directory)
            m.sync(root)
            self.assertEqual(json.loads((root / 'admission.json').read_text())['enrollments'], [])
            (root / 'credentials.compose.yml').touch()
            with self.assertRaisesRegex(ValueError, 'not installed'):
                m.sync(root)

    def test_installed_runner_and_failed_update_preserves_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'runner.yml'
            config.write_text('runnerId: personal\nagentWorker:\n  workspaceConfig: /private/workspace.json\n')
            binary = root / 'runner'
            binary.touch()
            properties = {'LoadState': 'loaded', 'Environment': f'LIGHT_WORKFLOW_RUNNER_CONFIG_FILE={config}', 'ExecStart': f'{{ path={binary} ; argv[]={binary} ; }}'}
            document = {'version': 1, 'origins': [], 'enrollments': [{'backends': [{'features': ['task-workspace-v1']}]}]}
            with patch.object(m, 'property_value', side_effect=properties.__getitem__), patch.object(m.subprocess, 'check_output', return_value=json.dumps(document)) as run:
                m.sync(root)
                self.assertEqual(run.call_args.args[0][0], str(binary))
                previous = (root / 'admission.json').read_bytes()
                before = (root / 'admission.json').stat().st_ino
                m.sync(root)
                self.assertEqual((root / 'admission.json').stat().st_ino, before)
                run.return_value = json.dumps({'version': 1, 'enrollments': [{'backends': []}]})
                with self.assertRaisesRegex(ValueError, 'task-workspace-v1'):
                    m.sync(root)
                self.assertEqual((root / 'admission.json').read_bytes(), previous)


if __name__ == '__main__':
    unittest.main()
