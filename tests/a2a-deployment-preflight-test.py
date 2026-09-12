#!/usr/bin/env python3
import copy
import datetime
import importlib.util
import json
import io
from contextlib import redirect_stderr
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('preflight', ROOT / 'scripts/verify-a2a-deployment.py')
preflight = importlib.util.module_from_spec(spec)
spec.loader.exec_module(preflight)


class Preflight(unittest.TestCase):
    def setUp(self):
        self.identity = {'host': 'dev.lightapi.net', 'serviceId': 'com.networknt.light-a2a-1.0.0', 'envTag': 'dev'}
        now = datetime.datetime.now(datetime.timezone.utc)
        self.record = {'properties': {
            **{'runtimePolicy.' + key: value for key, value in self.identity.items()},
            'runtimePolicy.audience': 'light-a2a', 'a2aPolicy.bindings': '[{"bindingId":"test"}]',
            'runtimePolicy.validFrom': (now - datetime.timedelta(hours=1)).isoformat(),
            'runtimePolicy.expiresAt': (now + datetime.timedelta(hours=1)).isoformat(),
            **{key: 'test' for key in ('runtimePolicy.publicationId', 'runtimePolicy.policyDigest',
                'operationalStore.bindingId', 'operationalStore.bindingDigest',
                'artifactStore.bindingId', 'artifactStore.bindingDigest')}}}

    def test_current_snapshot(self):
        preflight.validate_snapshot(self.record, self.identity)

    def test_rejects_missing_empty_expired_or_wrong_identity(self):
        with self.assertRaises(ValueError):
            preflight.validate_snapshot(None, self.identity)
        for key, value in [('a2aPolicy.bindings', '[]'), ('runtimePolicy.host', 'other.lightapi.net'),
                           ('runtimePolicy.expiresAt', '2000-01-01T00:00:00Z'),
                           ('runtimePolicy.publicationId', '')]:
            with self.subTest(key=key):
                record = copy.deepcopy(self.record)
                record['properties'][key] = value
                with self.assertRaises(ValueError):
                    preflight.validate_snapshot(record, self.identity)

    def test_image_failure_is_actionable_and_never_stops_stack(self):
        config = json.dumps({'services': {'light-a2a': {'image': 'missing:a2a'}}})
        failure = subprocess.CalledProcessError(1, ['docker'])
        with patch.object(preflight, 'run', side_effect=[config, failure, failure]) as run:
            with self.assertRaisesRegex(ValueError, 'A2A image is unavailable'):
                preflight.verify('docker', ['docker', 'compose'])
        self.assertEqual([call.args[0] for call in run.call_args_list], [
            ['docker', 'compose', 'config', '--format', 'json'],
            ['docker', 'image', 'inspect', 'missing:a2a'], ['docker', 'pull', 'missing:a2a']])

    def test_missing_snapshot_after_image_success(self):
        config = json.dumps({'services': {'light-a2a': {'image': 'local:a2a', 'volumes': [
            {'target': '/config', 'source': str(ROOT / 'all-in-lt/light-a2a-rust/config')}]
        }, 'postgres': {'container_name': 'postgres'}}})
        with patch.object(preflight, 'run', side_effect=[config, '[]', '']):
            with self.assertRaisesRegex(ValueError, 'found 0'):
                preflight.verify('docker', ['docker', 'compose'])

    def test_store_bindings_need_not_be_in_snapshot(self):
        for key in list(self.record['properties']):
            if key.startswith(('artifactStore.', 'operationalStore.')):
                del self.record['properties'][key]
        preflight.validate_snapshot(self.record, self.identity)

    def test_omitted_identity_uses_template_defaults(self):
        for key in ('serviceId', 'envTag', 'audience'):
            del self.record['properties']['runtimePolicy.' + key]
        preflight.validate_snapshot(self.record, self.identity)
        with self.assertRaisesRegex(ValueError, 'does not match startup'):
            preflight.validate_snapshot(self.record, self.identity | {'envTag': 'other'})

    def test_defaults_match_shipped_template(self):
        template = (ROOT / 'all-in-lt/light-a2a-rust/config/a2a.yml').read_text()
        for key, value in {'serviceId': self.identity['serviceId'], 'envTag': 'dev', 'audience': 'light-a2a'}.items():
            self.assertIn('${runtimePolicy.' + key + ':' + value + '}', template)

    def test_null_and_wrong_types_are_operator_errors(self):
        for key in ('a2aPolicy.bindings', 'runtimePolicy.validFrom', 'runtimePolicy.expiresAt'):
            for value in (None, 12, [], {}):
                with self.subTest(key=key, value=value):
                    record = copy.deepcopy(self.record)
                    record['properties'][key] = value
                    error_output = io.StringIO()
                    with patch.object(preflight, 'verify', side_effect=lambda *args: preflight.validate_snapshot(record, self.identity)), \
                         patch.object(preflight.sys, 'argv', ['diagnostic', 'docker']), redirect_stderr(error_output):
                        self.assertEqual(preflight.main(), 1)
                    self.assertIn('A2A diagnostic failed:', error_output.getvalue())
                    self.assertNotIn('Traceback', error_output.getvalue())

    def test_deployment_has_no_automatic_a2a_diagnostic(self):
        script = (ROOT / 'scripts/deploy-local.sh').read_text()
        self.assertNotIn('verify-a2a-deployment.py', script)

    def test_cold_deployment_bootstraps_before_full_start(self):
        # Exercise normal/start/restart dispatch with all side effects replaced.
        # This verifies a stopped DB cannot trigger the removed exec-before-up gate.
        script = (ROOT / 'scripts/deploy-local.sh').read_text()
        functions = script[script.index('main() {'):script.index('# Tests may source')]
        dispatch = script[script.index('# Handle script arguments'):]
        stubs = """
set -e
DOCKER_COMPOSE_DIR=/workspace/portal-config-loc/all-in-lt
BASE_DIR=/workspace
SCRIPT_DIR=/scripts
CONTROLLER_TYPE=rust
LOG_FILE=/tmp/unused
configure_release_image_env() { :; }
configure_light_portal_env() { :; }
configure_local_runtime_identity() { :; }
log_info() { :; }
log_success() { :; }
log_error() { :; }
check_prerequisites() { :; }
stop_docker_compose() { echo stop; }
apply_requested_db_patches() { echo patches; }
bootstrap_events_if_requested() { echo bootstrap; }
start_docker_compose() { echo start; }
show_summary() { :; }
sleep() { :; }
python3() {
  case "$1" in
    */personal-runner-lifecycle.py|*/sync-personal-runner-admission.py) return 0 ;;
    *) echo unexpected-diagnostic >&2; return 99 ;;
  esac
}
"""
        for action in ('', 'start', 'restart'):
            with self.subTest(action=action):
                result = subprocess.run(['bash', '-c', stubs + functions + dispatch, 'test'] + ([action] if action else []), text=True, capture_output=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                steps = result.stdout.splitlines()
                self.assertLess(steps.index('bootstrap'), steps.index('start'))


if __name__ == '__main__':
    unittest.main()
