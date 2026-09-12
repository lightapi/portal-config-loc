#!/usr/bin/env python3
import base64
import importlib.util
import json
import hashlib
import io
from contextlib import redirect_stdout
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('lifecycle', ROOT / 'scripts/personal-runner-lifecycle.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class LifecycleTest(unittest.TestCase):
    def test_optional_absent_but_incomplete_enrollment_rejected(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(m, 'system_property', return_value='not-found'):
            root = Path(directory)
            self.assertEqual(m.configured_runners(root), [])
            runtime = root / 'light-workflow-runner-claude-personal/.runtime'
            runtime.mkdir(parents=True)
            (runtime / 'runner.yml').touch()
            with self.assertRaisesRegex(ValueError, 'not installed'):
                m.configured_runners(root)

    def test_expired_token_diagnostic_does_not_expose_credentials(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'token'
            payload = base64.urlsafe_b64encode(json.dumps({'exp': 900, 'secret': 'DO_NOT_LOG'}).encode()).decode().rstrip('=')
            path.write_text('header.' + payload + '.signature')
            with self.assertRaisesRegex(ValueError, 'issuer token expired') as error:
                m.check_token(path, 'runner', now=1000)
            self.assertNotIn('DO_NOT_LOG', str(error.exception))
            payload = base64.urlsafe_b64encode(b'{"exp":100000}').decode().rstrip('=')
            path.write_text('header.' + payload + '.signature')
            m.check_token(path, 'runner', now=1000)

    def runner(self):
        return dict(unit='runner.service', config={'healthAddress': '127.0.0.1:9445',
                    'backend': {'compatibilityDigest': 'sha256:new'}})

    def health(self):
        return dict(status='healthy', controllerConnected=True, backendHealthy=True, journalHealthy=True,
                    watchdogHealthy=True, orphanReconciliationHealthy=True)

    def test_http_200_disconnected_and_old_compatibility_are_not_ready(self):
        runner = self.runner()
        health = self.health()
        health['controllerConnected'] = False
        with patch.object(m, 'verify_running_identity'), patch.object(m, 'read_http', return_value=json.dumps(health)):
            with self.assertRaisesRegex(ValueError, 'Controller-connected'):
                m.check_ready(runner)
        metrics = 'light_runner_backend_info{backend_id="worker",compatibility_digest="sha256:old"} 1\n'
        with patch.object(m, 'verify_running_identity'), patch.object(m, 'read_http', side_effect=[json.dumps(self.health()), metrics]):
            with self.assertRaisesRegex(ValueError, 'compatibility differs'):
                m.check_ready(runner)

    def test_current_identity_and_connected_backend_are_ready(self):
        metrics = 'light_runner_backend_info{backend_id="worker",compatibility_digest="sha256:new"} 1\n'
        with patch.object(m, 'verify_running_identity'), patch.object(m, 'read_http', side_effect=[json.dumps(self.health()), metrics]):
            m.check_ready(self.runner())

    def test_timeout_fails_instead_of_reporting_deployment_success(self):
        with patch.object(m, 'check_ready', side_effect=ValueError('Controller disconnected')), \
             patch.object(m.time, 'monotonic', side_effect=[0, 10]):
            with self.assertRaisesRegex(ValueError, 'readiness timed out'):
                m.wait_ready(self.runner(), 1)

    def test_active_old_runner_is_restarted_then_verified(self):
        # An active old process must still receive restart, never merely start.
        runner = self.runner()
        calls = []
        with patch.object(m, 'configured_runners', return_value=[runner]), \
             patch.object(m, 'preflight', side_effect=lambda r: calls.append('preflight')), \
             patch.object(m.subprocess, 'run', side_effect=lambda command, **kw: calls.append(command[2])), \
             patch.object(m, 'wait_ready', side_effect=lambda r, t: calls.append('verify')):
            m.run(Path('/tmp'), 'restart', 2)
        self.assertEqual(calls, ['preflight', 'restart', 'verify'])

    def test_preflight_failure_changes_no_processes(self):
        with patch.object(m, 'configured_runners', return_value=[self.runner()]), \
             patch.object(m, 'preflight', side_effect=ValueError('issuer token expired')), \
             patch.object(m.subprocess, 'run') as restart:
            with self.assertRaisesRegex(ValueError, 'expired'):
                m.run(Path('/tmp'), 'restart', 2)
            restart.assert_not_called()

    def test_native_expiry_is_distinct_and_malformed_metadata_is_not_logged(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'coding-profile.json').write_text('{"binaryDigest":"sha256:pin"}')
            runner = dict(unit='claude', runtime=root, config={
                'jwtFile': str(root / 'runner.jwt'), 'healthAddress': '127.0.0.1:9445',
                'agentWorker': dict(executable='worker', binaryDigest='sha256:pin',
                    claudeExecutable='claude', claudeHome=str(root))})
            for expiry in [0, 'PRIVATE_TOKEN_MUST_NOT_APPEAR']:
                (root / '.credentials.json').write_text(json.dumps({'claudeAiOauth': {'expiresAt': expiry}}))
                with patch.object(m, 'check_token'), patch.object(m, 'file_digest', return_value='sha256:pin'):
                    with self.assertRaisesRegex(ValueError, 'native.*login') as error:
                        m.preflight(runner)
                    self.assertNotIn('PRIVATE_TOKEN_MUST_NOT_APPEAR', str(error.exception))

    def test_health_endpoint_rejects_nonlocal_destination(self):
        for address in ['0.0.0.0:9445', '192.0.2.1:9445', 'localhost:9445', '127.0.0.1:0']:
            with self.assertRaises(ValueError):
                m.health_url({'healthAddress': address})

    def test_storage_inventory_preserves_ready_uncertain_and_closed_state(self):
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory)
            home = parent / '.claude'
            home.mkdir()
            key = hashlib.sha256(bytes(home)).hexdigest()
            records = parent / ('.light-claude-checkpoints-' + key) / 'light-worker-threads'
            records.mkdir(parents=True)
            for state in ['READY', 'IN_FLIGHT', 'CLOSED']:
                (records / (state + '.json')).write_text(json.dumps({'state': state}))
            native = parent / '.light-claude-native-example'
            native.mkdir()
            (native / 'transcript').write_text('PRIVATE_CONTENT')
            before = {str(p): p.read_bytes() for p in parent.rglob('*') if p.is_file()}
            output = io.StringIO()
            with redirect_stdout(output):
                m.storage_report(dict(unit='claude', config={'agentWorker': {'claudeHome': str(home)}}))
            report = json.loads(output.getvalue())
            self.assertEqual(report['checkpointStates']['IN_FLIGHT'], 1)
            self.assertFalse(report['deletionPerformed'])
            self.assertNotIn('PRIVATE_CONTENT', output.getvalue())
            self.assertEqual(before, {str(p): p.read_bytes() for p in parent.rglob('*') if p.is_file()})

    def test_workspace_storage_reports_both_adapters_without_transcripts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            native = root / 'native-conversations'
            records = native / 'light-worker-threads'; records.mkdir(parents=True)
            for state in ['READY', 'IN_FLIGHT', 'CLOSED']:
                (records / (state+'.json')).write_text(json.dumps({'state':state}))
            home=native / ('a'*64);home.mkdir();(home/'transcript').write_text('PRIVATE_CONTENT')
            config=root/'workspace.json';config.write_text(json.dumps({'store':str(root)}))
            for name in ['codex','claude']:
                output=io.StringIO()
                with redirect_stdout(output):
                    m.storage_report(dict(unit=name,config={'agentWorker':{'workspaceConfig':str(config)}}))
                report=json.loads(output.getvalue())
                self.assertEqual(report['nativeDirectories'],1)
                self.assertEqual(report['nativeBytes'],len('PRIVATE_CONTENT'))
                self.assertEqual(report['checkpointStates']['IN_FLIGHT'],1)
                self.assertNotIn('PRIVATE_CONTENT',output.getvalue())
                self.assertTrue((home/'transcript').exists())

    def test_installer_full_start_restarts_after_compose_and_propagates_failure(self):
        installer = ROOT.parent / 'light-portal-install/install.sh'
        text = installer.read_text()
        function = 'start_stack() {' + text.split('start_stack() {', 1)[1].split('\n}', 1)[0] + '\n}'
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / '.env').touch()
            runtime = root / 'light-workflow-runner-claude-personal/.runtime'
            runtime.mkdir(parents=True)
            (runtime / 'runner.yml').touch()
            script = '''set -e
require_command() { :; }
ensure_knowledge_runtime() { :; }
compose() { echo compose; }
python3() { echo lifecycle "$@"; return 7; }
''' + function + '\nstart_stack\n'
            result = subprocess.run(['bash', '-c', script], cwd=root, capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(result.stdout.splitlines(), ['compose', 'lifecycle scripts/personal-runner-lifecycle.py restart .'])


if __name__ == '__main__':
    unittest.main()
