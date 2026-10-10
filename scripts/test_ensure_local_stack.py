"""Container/database doubles exercise the local startup contract before live use."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('startup', Path(__file__).with_name('ensure-local-stack.py'))
s = importlib.util.module_from_spec(spec)
spec.loader.exec_module(s)


def container(name, status='running', code=0):
    return dict(Id=name, Image='sha256:' + name,
                Config=dict(Labels={'com.docker.compose.service': name}, User='1001:1234'),
                State=dict(Status=status, ExitCode=code, Health={'Status': 'healthy'}))


class StartupTests(unittest.TestCase):
    def setUp(self):
        self.services = {'postgres': {'image': 'pg:local'},
                         'init': {'image': 'init:local', 'depends_on': {'postgres': {'condition': 'service_healthy'}}},
                         'app': {'image': 'app:local', 'depends_on': {'init': {'condition': 'service_completed_successfully'}}}}
        self.config = {'services': self.services}
        self.current = {n: container(n) for n in self.services}
        self.current['init'] = container('init', 'exited')
        self.calls = []
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        state = self.base / 'postgres-db/operations/.runtime/w7/prepared.json'
        state.parent.mkdir(parents=True)
        state.write_text('{}')

    def tearDown(self):
        self.temp.cleanup()

    def command(self, argv, **kwargs):
        self.calls.append(argv)
        if argv[:3] == ['docker', 'image', 'inspect']:
            return 'sha256:' + {'pg:local': 'postgres', 'init:local': 'init', 'app:local': 'app'}[argv[3]]
        if argv[:2] == ['docker', 'start']:
            self.current[argv[2]]['State']['Status'] = 'running'
            return argv[2]
        if argv[:2] == ['docker', 'stop']:
            self.current[argv[-1]]['State']['Status'] = 'exited'
            return argv[-1]
        if argv[:3] == ['docker', 'compose', 'up']:
            name = argv[-1]
            self.current[name]['Image'] = 'sha256:' + name
            self.current[name]['State']['Status'] = 'running'
            return ''
        raise AssertionError('Unexpected container command: ' + repr(argv))

    def ensure(self, protected=None):
        with patch.object(s, 'BASE', self.base), patch.object(s, 'containers', return_value=self.current), patch.object(s, 'configuration', return_value=(self.config, ['docker', 'compose'], {})), patch.object(s, 'run', side_effect=self.command), patch.object(s, 'wait'), patch.object(s, 'readiness'), patch.object(s, 'protected', side_effect=protected or [({'backup': 'verified'}, list(range(49)), 'restricted_acl')] * 2):
            s.ensure()

    def test_healthy_stack_noop_and_successful_oneshot_reused(self):
        self.ensure()
        self.assertTrue(all(c[:3] == ['docker', 'image', 'inspect'] for c in self.calls))

    def test_bare_lt_dispatches_only_local_helper(self):
        executable = self.base / 'python3'
        executable.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
        executable.chmod(0o700)
        env = dict(os.environ, PATH=str(self.base) + ':' + os.environ['PATH'])
        for args in (['lt'], ['lt', 'rust']):
            result = subprocess.run(['bash', str(s.ROOT / 'scripts/deploy-local.sh'), *args],
                                    env=env, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout.splitlines(), ['-B', str(s.ROOT / 'scripts/ensure-local-stack.py')])
            self.assertEqual(result.stderr, '')
        for action in ('stop', 'status', 'logs'):
            for args in (['lt', action], ['lt', 'rust', action]):
                result = subprocess.run(['bash', str(s.ROOT / 'scripts/deploy-local.sh'), *args],
                                        env=env, text=True, capture_output=True)
                self.assertEqual(result.returncode, 0)
                self.assertEqual(result.stdout.splitlines(),
                                 ['-B', str(s.ROOT / 'scripts/ensure-local-stack.py'), action])

    def test_stop_retains_containers_and_data(self):
        with patch.object(s, 'containers', return_value=self.current), patch.object(s, 'configuration', return_value=(self.config, ['docker', 'compose'], {'PRIVATE': 'retained'})), patch.object(s.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0)) as command:
            s.control('stop')
        self.assertEqual(command.call_args.args[0], ['docker', 'compose', 'stop', '--timeout', '30'])
        self.assertEqual(command.call_args.kwargs['env'], {'PRIVATE': 'retained'})
        self.assertFalse(any(x in command.call_args.args[0] for x in ('down', '-v', '--remove-orphans')))

    def test_stopped_services_start_in_order_without_setup(self):
        self.current['postgres'] = container('postgres', 'exited')
        self.current['app'] = container('app', 'exited')
        self.ensure()
        self.assertEqual([c for c in self.calls if c[:2] == ['docker', 'start']],
                         [['docker', 'start', 'postgres'], ['docker', 'start', 'app']])

    def test_reboot_recovers_restarting_app_after_database_readiness(self):
        self.current['postgres'] = container('postgres', 'exited', 255)
        self.current['app'] = container('app', 'restarting', 1)
        self.current['app']['State']['Health']['Status'] = 'unhealthy'
        def ready(item):
            self.assertEqual(item['State']['Status'], 'running')
            self.calls.append(['ready', item['Id']])
        with patch.object(s, 'wait', side_effect=ready) as wait:
            # ensure() patches wait itself, so use the same setup directly.
            with patch.object(s, 'BASE', self.base), patch.object(s, 'containers', return_value=self.current), patch.object(s, 'configuration', return_value=(self.config, ['docker', 'compose'], {})), patch.object(s, 'run', side_effect=self.command), patch.object(s, 'readiness'), patch.object(s, 'protected', return_value='unchanged'):
                s.ensure()
            self.assertTrue(wait.called)
        mutations = [c for c in self.calls if c[:2] in (['docker', 'start'], ['docker', 'stop'])]
        self.assertEqual(mutations, [['docker', 'start', 'postgres'],
                                     ['docker', 'stop', '--timeout', '30', 'app'],
                                     ['docker', 'start', 'app']])
        self.assertLess(self.calls.index(['ready', 'postgres']),
                        self.calls.index(['docker', 'stop', '--timeout', '30', 'app']))
        self.calls.clear()
        self.current['app']['State']['Health']['Status'] = 'healthy'
        self.ensure()
        self.assertFalse(any(c[:2] in (['docker', 'start'], ['docker', 'stop']) for c in self.calls))

    def test_restarting_database_and_unsafe_apps_refuse_before_changes(self):
        for name, status in [('postgres', 'restarting'), ('app', 'paused'), ('app', 'dead'), ('app', 'removing')]:
            with self.subTest(name=name, status=status):
                self.current['postgres'] = container('postgres', 'exited')
                self.current['app'] = container('app')
                self.current[name]['State']['Status'] = status
                self.calls.clear()
                with self.assertRaisesRegex(ValueError, 'unsafe state'):
                    self.ensure()
                self.assertFalse(any(c[:2] in (['docker', 'start'], ['docker', 'stop']) or c[:3] == ['docker', 'compose', 'up'] for c in self.calls))

    def test_stopped_containers_ignore_stale_shutdown_health(self):
        for name in ('postgres', 'app'):
            self.current[name] = container(name, 'exited')
            self.current[name]['State']['Health']['Status'] = 'unhealthy'
        self.ensure()
        self.assertEqual([c for c in self.calls if c[:2] == ['docker', 'start']],
                         [['docker', 'start', 'postgres'], ['docker', 'start', 'app']])

    def test_running_unhealthy_container_refuses_before_any_start(self):
        self.current['postgres'] = container('postgres', 'exited')
        self.current['app']['State']['Health']['Status'] = 'unhealthy'
        with self.assertRaisesRegex(ValueError, 'Service app is unhealthy'):
            self.ensure()
        self.assertFalse(any(c[:2] == ['docker', 'start'] for c in self.calls))

    def test_wait_requires_fresh_health_after_start(self):
        states = [dict(Status='running', Health={'Status': 'starting'}),
                  dict(Status='running', Health={'Status': 'healthy'})]
        with patch.object(s, 'run', side_effect=[json.dumps([{'State': state}]) for state in states]) as command, patch.object(s.time, 'sleep') as sleep:
            s.wait(self.current['postgres'])
        self.assertEqual(command.call_count, 2)
        sleep.assert_called_once_with(2)

    def test_missing_container_stops_before_changes(self):
        del self.current['init']
        with self.assertRaisesRegex(ValueError, 'container is missing: init'):
            self.ensure()
        self.assertFalse(any(c[:2] == ['docker', 'start'] for c in self.calls))

    def test_failed_initialization_is_never_rerun(self):
        self.current['init']['State']['ExitCode'] = 1
        with self.assertRaisesRegex(ValueError, 'one-shot is incomplete'):
            self.ensure()
        self.assertFalse(any(c[:2] == ['docker', 'start'] for c in self.calls))

    def test_changed_app_image_recreates_only_that_app_without_dependencies(self):
        self.current['app']['Image'] = 'wrong'
        self.ensure()
        # Once deployed, the same invocation must become a no-op.
        self.ensure()
        updates = [c for c in self.calls if c[:3] == ['docker', 'compose', 'up']]
        self.assertEqual(updates, [['docker', 'compose', 'up', '-d', '--no-deps', '--no-build', '--pull', 'never', '--force-recreate', 'app']])
        self.assertFalse(any(c[:2] == ['docker', 'start'] for c in self.calls))

    def test_changed_oneshot_image_reuses_completed_initialization(self):
        self.current['init']['Image'] = 'historical-image'
        self.ensure()
        self.assertFalse(any(c[:2] == ['docker', 'start'] or c[:3] == ['docker', 'compose', 'up'] for c in self.calls))

    def test_changed_database_image_refuses_before_changes(self):
        self.current['postgres']['Image'] = 'old-postgres'
        with self.assertRaisesRegex(ValueError, 'PostgreSQL image differs'):
            self.ensure()
        self.assertFalse(any(c[:2] == ['docker', 'start'] or c[:3] == ['docker', 'compose', 'up'] for c in self.calls))

    def test_missing_schema_or_policy_acl_stops_before_dependents(self):
        self.current['app'] = container('app', 'exited')
        self.current['app']['Image'] = 'rebuilt-local-image-pending'
        with self.assertRaisesRegex(ValueError, 'schema or ACL'):
            self.ensure(protected=ValueError('schema or ACL missing'))
        self.assertFalse(any(c[:2] == ['docker', 'start'] for c in self.calls))
        self.assertFalse(any(c[:3] == ['docker', 'compose', 'up'] for c in self.calls))

    def test_actual_runtime_validator_refuses_policy_permissions_and_activation(self):
        runtime = s.module('check-local-portal-runtime')
        keys = ['policy_admission_update_forbidden', 'policy_insert_forbidden',
                'policy_delete_forbidden', 'policy_truncate_forbidden', 'policy_off']
        for key in keys:
            values = {name: True for name in keys}
            values[key] = False
            result = subprocess.CompletedProcess([], 0, json.dumps(values), '')
            with patch.object(runtime.subprocess, 'run', return_value=result) as command:
                with self.assertRaisesRegex(ValueError, key):
                    runtime.validate()
                argv = command.call_args.args[0]
                self.assertEqual(argv[:4], ['docker', 'exec', '-i', 'postgres'])
                self.assertTrue(command.call_args.kwargs['input'].startswith('BEGIN READ ONLY;'))
                self.assertTrue(command.call_args.kwargs['input'].rstrip().endswith('ROLLBACK;'))

    def test_protected_data_and_policy_acl_changes_fail(self):
        for field in range(3):
            before = ['backup', '49 definitions', 'restricted ACL']
            after = before.copy()
            after[field] = 'changed'
            with self.assertRaisesRegex(ValueError, 'Protected local data changed'):
                self.ensure(protected=[before, after])

    def test_environment_order_private_selection_and_no_download(self):
        release, private = self.base / 'release.env', self.base / 'light-portal.env'
        release.write_text('LIGHT_WORKFLOW_IMAGE=release')
        private.write_text('LIGHT_WORKFLOW_IMAGE=local')
        current = {'w7-controller-page-readiness': container('readiness', 'exited')}
        seen = []
        def render(argv, **kw):
            seen.append((argv, kw['env']))
            return json.dumps({'name': 'all-in-lt', 'services': {}})
        with patch.object(s, 'BASE', self.base), patch.dict(os.environ, {'RELEASE_IMAGE_ENV_FILE': str(release), 'LIGHT_PORTAL_ENV_FILE': str(private), 'LIGHT_WORKFLOW_IMAGE': 'stale'}), patch.object(s, 'run', side_effect=render):
            s.configuration(current)
        argv, env = seen[0]
        files = [argv[i+1] for i, value in enumerate(argv) if value == '--env-file']
        self.assertEqual(files, [str(release), str(private)])
        self.assertNotIn('LIGHT_WORKFLOW_IMAGE', env)
        self.assertEqual(env['W7_READINESS_GID'], '1234')
        self.assertEqual(env['IMPORT_EVENTS'], 'false')
        self.assertEqual(argv[-3:], ['config', '--format', 'json'])
        private.unlink()
        with patch.object(s, 'BASE', self.base), patch.dict(os.environ, {'RELEASE_IMAGE_ENV_FILE': str(release), 'LIGHT_PORTAL_ENV_FILE': str(private)}), patch.object(s, 'run') as command:
            with self.assertRaisesRegex(ValueError, 'environment file is missing'):
                s.configuration(current)
            command.assert_not_called()


if __name__ == '__main__':
    unittest.main()
